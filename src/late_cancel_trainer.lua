-- ============================================================================
-- LATE CANCEL TRAINER MODULE
-- ============================================================================
-- Chun-Li cr.MK Late Cancel Timing Analysis
-- Integrated into Grouflon's 3rd Strike Training Mode
-- ============================================================================

late_cancel_trainer = {
    -- Configuration
    config = {
        LATE_CANCEL_START_FRAME = 23,
        LATE_CANCEL_END_FRAME = 24,
        MOTION_INPUT_WINDOW = 120,
        DIRECTION_BUFFER_SIZE = 30,
        KICK_BUTTONS = {"Weak Kick", "Medium Kick", "Strong Kick"}
    },
    
    -- Direction constants
    DIR_DOWN = 2,
    DIR_DOWN_FORWARD = 3,
    DIR_FORWARD = 6,
    DIR_DOWN_BACK = 1,
    DIR_BACK = 4,
    DIR_NEUTRAL = 5,
    
    -- State
    direction_buffer = {},
    last_direction = 5,  -- DIR_NEUTRAL
    kick_presses = {},
    last_button_state = {},
    waiting_for_crmk = true,
    waiting_for_super = false,
    crmk_frame = 0,
    crmk_button = nil,
    ignore_crmk_release = false,
    motion_count = 0,
    motion_type = nil,
    motion_start_frame = 0,
    
    -- Statistics
    stats = {
        attempts = 0,
        perfect = 0,
        early = 0,
        late = 0,
        failed = 0
    },
    
    -- Display
    messages = {},
    result_message = "",
    show_result_frames = 0,
    
    -- Cooldown to prevent accidental re-triggers
    cooldown_frames = 0
}

-- Direction names for display
local DIR_NAMES = {
    [2] = "DOWN",
    [3] = "DOWN-FWD",
    [6] = "FORWARD",
    [1] = "DOWN-BACK",
    [4] = "BACK",
    [5] = "NEUTRAL"
}

local BUTTON_NAMES = {
    ["Weak Kick"] = "LK",
    ["Medium Kick"] = "MK",
    ["Strong Kick"] = "HK"
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function table_append(tbl, item, max_size)
    table.insert(tbl, 1, item)
    while #tbl > max_size do
        table.remove(tbl)
    end
end

local function get_direction_from_input(input)
    local p1_up = input["P1 Up"]
    local p1_down = input["P1 Down"]
    local p1_left = input["P1 Left"]
    local p1_right = input["P1 Right"]
    
    if p1_down and p1_right then
        return late_cancel_trainer.DIR_DOWN_FORWARD
    elseif p1_down and p1_left then
        return late_cancel_trainer.DIR_DOWN_BACK
    elseif p1_down then
        return late_cancel_trainer.DIR_DOWN
    elseif p1_right then
        return late_cancel_trainer.DIR_FORWARD
    elseif p1_left then
        return late_cancel_trainer.DIR_BACK
    else
        return late_cancel_trainer.DIR_NEUTRAL
    end
end

-- ============================================================================
-- MOTION DETECTION
-- ============================================================================

local function detect_motion(sequence, allow_end_variant, end_variant)
    if #late_cancel_trainer.direction_buffer < #sequence then
        return false, -1
    end
    
    local directions = {}
    for i = 1, #late_cancel_trainer.direction_buffer do
        table.insert(directions, late_cancel_trainer.direction_buffer[i].dir)
    end
    
    -- More lenient detection: allow the sequence to appear anywhere in the buffer
    -- This matches SF3's actual input leniency
    local seq_idx = 1
    local last_match_pos = -1
    
    for i = 1, #directions do
        if directions[i] == sequence[seq_idx] then
            seq_idx = seq_idx + 1
            last_match_pos = i
            
            -- Check if we completed the sequence
            if seq_idx > #sequence then
                return true, last_match_pos
            end
            
            -- Check for shortcut ending (e.g., QCF can end on down-forward)
            if allow_end_variant and seq_idx == #sequence and directions[i] == end_variant then
                return true, last_match_pos
            end
        elseif seq_idx > 1 then
            -- If we're in the middle of a sequence and hit a non-matching input,
            -- check if this input could restart the sequence
            if directions[i] == sequence[1] then
                seq_idx = 2  -- Restart from second element
                last_match_pos = i
            end
        end
    end
    
    return false, -1
end

local function detect_qcf(allow_incomplete)
    -- QCF: Down, Down-Forward, Forward
    -- Allow ending on Down-Forward for shortcuts
    local detected, end_pos = detect_motion(
        {late_cancel_trainer.DIR_DOWN, late_cancel_trainer.DIR_DOWN_FORWARD, late_cancel_trainer.DIR_FORWARD},
        allow_incomplete or false,
        late_cancel_trainer.DIR_DOWN_FORWARD
    )
    
    -- Additional leniency: also accept if we see Down-Forward → Forward (skipping initial down)
    -- This handles cases where down was held before MK
    if not detected and allow_incomplete then
        local directions = {}
        for i = 1, #late_cancel_trainer.direction_buffer do
            table.insert(directions, late_cancel_trainer.direction_buffer[i].dir)
        end
        
        -- Look for Down-Forward → Forward pattern (partial QCF)
        for i = 1, #directions - 1 do
            if directions[i] == late_cancel_trainer.DIR_DOWN_FORWARD and 
               (directions[i+1] == late_cancel_trainer.DIR_FORWARD or 
                directions[i+1] == late_cancel_trainer.DIR_DOWN_FORWARD) then
                return true, i+1
            end
        end
    end
    
    return detected, end_pos
end

local function detect_qcb(allow_incomplete)
    -- QCB: Down, Down-Back, Back
    -- Allow ending on Down-Back for shortcuts
    local detected, end_pos = detect_motion(
        {late_cancel_trainer.DIR_DOWN, late_cancel_trainer.DIR_DOWN_BACK, late_cancel_trainer.DIR_BACK},
        allow_incomplete or false,
        late_cancel_trainer.DIR_DOWN_BACK
    )
    
    -- Additional leniency: also accept if we see Down-Back → Back (skipping initial down)
    if not detected and allow_incomplete then
        local directions = {}
        for i = 1, #late_cancel_trainer.direction_buffer do
            table.insert(directions, late_cancel_trainer.direction_buffer[i].dir)
        end
        
        -- Look for Down-Back → Back pattern (partial QCB)
        for i = 1, #directions - 1 do
            if directions[i] == late_cancel_trainer.DIR_DOWN_BACK and 
               (directions[i+1] == late_cancel_trainer.DIR_BACK or 
                directions[i+1] == late_cancel_trainer.DIR_DOWN_BACK) then
                return true, i+1
            end
        end
    end
    
    return detected, end_pos
end

-- ============================================================================
-- TIMING ANALYSIS
-- ============================================================================

local function check_timing(elapsed_frames)
    -- elapsed_frames is already the correct frame number (0 = same frame as MK, 1 = next frame, etc.)
    local frame = elapsed_frames
    local cfg = late_cancel_trainer.config
    
    if frame >= cfg.LATE_CANCEL_START_FRAME and frame <= cfg.LATE_CANCEL_END_FRAME then
        return "PERFECT", frame
    elseif frame < cfg.LATE_CANCEL_START_FRAME then
        return "EARLY", frame
    else
        return "LATE", frame
    end
end

-- ============================================================================
-- TRIAL MANAGEMENT
-- ============================================================================

local function start_trial(button_name, current_frame, current_direction)
    late_cancel_trainer.crmk_frame = current_frame
    late_cancel_trainer.crmk_button = button_name
    late_cancel_trainer.ignore_crmk_release = true
    late_cancel_trainer.waiting_for_crmk = false
    late_cancel_trainer.waiting_for_super = true
    late_cancel_trainer.motion_count = 0
    late_cancel_trainer.motion_type = nil
    late_cancel_trainer.kick_presses = {}
    late_cancel_trainer.messages = {}
    
    -- Input buffering
    if current_direction == late_cancel_trainer.DIR_DOWN or 
       current_direction == late_cancel_trainer.DIR_DOWN_BACK or 
       current_direction == late_cancel_trainer.DIR_DOWN_FORWARD then
        table_append(late_cancel_trainer.direction_buffer, {
            dir = current_direction,
            frame = current_frame
        }, late_cancel_trainer.config.DIRECTION_BUFFER_SIZE)
    end
    
    table.insert(late_cancel_trainer.messages, "[cr.MK pressed] Perform QCF/QCF + Kick!")
end

local function record_kick(button_name, elapsed_frames, input_type)
    table.insert(late_cancel_trainer.kick_presses, {
        button = button_name,
        frame = elapsed_frames,
        type = input_type
    })
end

local function register_first_motion(motion_type, current_frame, end_index)
    late_cancel_trainer.motion_count = 1
    late_cancel_trainer.motion_type = motion_type
    late_cancel_trainer.motion_start_frame = current_frame
    table.insert(late_cancel_trainer.messages, "    ✓ " .. motion_type .. " 1/2 detected")
    
    if end_index > 0 then
        local remaining = {}
        for i = end_index + 1, #late_cancel_trainer.direction_buffer do
            table.insert(remaining, late_cancel_trainer.direction_buffer[i])
        end
        late_cancel_trainer.direction_buffer = remaining
    end
end

local function register_second_motion(motion_type)
    late_cancel_trainer.motion_count = 2
    table.insert(late_cancel_trainer.messages, "    ✓ " .. motion_type .. " 2/2 detected")
end

local function process_results()
    late_cancel_trainer.stats.attempts = late_cancel_trainer.stats.attempts + 1
    
    local perfect_found = false
    local best_result = nil
    local best_frame = nil
    local best_input_type = nil
    
    for _, kick in ipairs(late_cancel_trainer.kick_presses) do
        local result, frame = check_timing(kick.frame)
        if result == "PERFECT" then
            perfect_found = true
            best_result = result
            best_frame = frame
            best_input_type = kick.type
            break
        elseif best_result == nil or (result == "EARLY" and best_result == "LATE") then
            best_result = result
            best_frame = frame
            best_input_type = kick.type
        end
    end
    
    local edge = ""
    if best_input_type == "release" then
        edge = " [negative edge]"
    end
    
    local cfg = late_cancel_trainer.config
    if perfect_found then
        late_cancel_trainer.stats.perfect = late_cancel_trainer.stats.perfect + 1
        late_cancel_trainer.result_message = "    ✓✓ PERFECT! Frame " .. best_frame .. edge .. " - Late cancel successful!"
    elseif best_result == "EARLY" then
        late_cancel_trainer.stats.early = late_cancel_trainer.stats.early + 1
        local diff = cfg.LATE_CANCEL_START_FRAME - best_frame
        late_cancel_trainer.result_message = "    ✗ EARLY - Frame " .. best_frame .. edge .. " (" .. diff .. "f too early)"
    else
        late_cancel_trainer.stats.late = late_cancel_trainer.stats.late + 1
        local diff = best_frame - cfg.LATE_CANCEL_END_FRAME
        late_cancel_trainer.result_message = "    ✗ LATE - Frame " .. best_frame .. edge .. " (" .. diff .. "f too late)"
    end
    
    if #late_cancel_trainer.kick_presses > 1 then
        local piano_str = "    [Piano: "
        for i, kick in ipairs(late_cancel_trainer.kick_presses) do
            if i > 1 then piano_str = piano_str .. " → " end
            local type_char = kick.type == "press" and "p" or "r"
            piano_str = piano_str .. BUTTON_NAMES[kick.button] .. "(" .. type_char .. ")"
        end
        piano_str = piano_str .. "]"
        late_cancel_trainer.result_message = late_cancel_trainer.result_message .. "\n" .. piano_str
    end
    
    late_cancel_trainer.show_result_frames = 180
end

local function handle_timeout()
    late_cancel_trainer.stats.attempts = late_cancel_trainer.stats.attempts + 1
    late_cancel_trainer.stats.failed = late_cancel_trainer.stats.failed + 1
    
    if #late_cancel_trainer.kick_presses > 0 then
        if late_cancel_trainer.motion_count == 0 then
            late_cancel_trainer.result_message = "    ✗ MISSED MOTION - No motion detected"
        elseif late_cancel_trainer.motion_count == 1 then
            late_cancel_trainer.result_message = "    ✗ MISSED MOTION - Only 1 " .. late_cancel_trainer.motion_type .. " detected"
        end
    else
        if late_cancel_trainer.motion_count == 2 then
            late_cancel_trainer.result_message = "    ✗ MISSED MOTION - Motion complete but no kick"
        else
            late_cancel_trainer.result_message = "    ✗ MISSED MOTION - Incomplete input"
        end
    end
    
    late_cancel_trainer.show_result_frames = 180
end

local function reset_round()
    late_cancel_trainer.waiting_for_crmk = true
    late_cancel_trainer.waiting_for_super = false
    late_cancel_trainer.cooldown_frames = 30  -- 30 frame cooldown (~0.5 seconds) to prevent accidental re-trigger
    late_cancel_trainer.messages = {"Press crMK to start"}
end

-- ============================================================================
-- UPDATE FUNCTION (called from main script)
-- ============================================================================

function update_late_cancel_trainer(_input)
    -- Check if enabled via menu (training_settings is a global from main script)
    if not training_settings or not training_settings.late_cancel_trainer_enabled then
        return
    end
    
    local current_frame = emu.framecount()
    
    -- Safety check
    if not _input then
        return
    end
    
    -- Update direction buffer
    local current_direction = get_direction_from_input(_input)
    if current_direction ~= late_cancel_trainer.last_direction then
        table_append(late_cancel_trainer.direction_buffer, {
            dir = current_direction,
            frame = current_frame
        }, late_cancel_trainer.config.DIRECTION_BUFFER_SIZE)
        late_cancel_trainer.last_direction = current_direction
    end
    
    -- Clean old inputs
    while #late_cancel_trainer.direction_buffer > 0 do
        local oldest = late_cancel_trainer.direction_buffer[#late_cancel_trainer.direction_buffer]
        if current_frame - oldest.frame > late_cancel_trainer.config.MOTION_INPUT_WINDOW then
            table.remove(late_cancel_trainer.direction_buffer)
        else
            break
        end
    end
    
    -- Decrement cooldown
    if late_cancel_trainer.cooldown_frames > 0 then
        late_cancel_trainer.cooldown_frames = late_cancel_trainer.cooldown_frames - 1
    end
    
    -- Button detection
    for _, button_name in ipairs(late_cancel_trainer.config.KICK_BUTTONS) do
        local button_key = "P1 " .. button_name
        local current_state = _input[button_key]
        local last_state = late_cancel_trainer.last_button_state[button_name] or false
        
        if current_state and not last_state then
            -- Only start new trial if not in cooldown
            if late_cancel_trainer.waiting_for_crmk and button_name == "Medium Kick" and late_cancel_trainer.cooldown_frames == 0 then
                start_trial(button_name, current_frame, current_direction)
            elseif late_cancel_trainer.waiting_for_super then
                local elapsed = current_frame - late_cancel_trainer.crmk_frame
                record_kick(button_name, elapsed, "press")
            end
        end
        
        if not current_state and last_state then
            if late_cancel_trainer.waiting_for_super then
                if button_name == late_cancel_trainer.crmk_button and late_cancel_trainer.ignore_crmk_release then
                    late_cancel_trainer.ignore_crmk_release = false
                else
                    local elapsed = current_frame - late_cancel_trainer.crmk_frame
                    record_kick(button_name, elapsed, "release")
                end
            end
        end
        
        late_cancel_trainer.last_button_state[button_name] = current_state
    end
    
    -- Motion detection
    if late_cancel_trainer.waiting_for_super then
        local elapsed_frames = current_frame - late_cancel_trainer.crmk_frame
        
        if late_cancel_trainer.motion_count == 0 then
            local qcf_detected, qcf_end = detect_qcf(false)
            local qcb_detected, qcb_end = detect_qcb(false)
            
            if qcf_detected then
                register_first_motion("QCF", current_frame, qcf_end)
            elseif qcb_detected then
                register_first_motion("QCB", current_frame, qcb_end)
            end
        
        elseif late_cancel_trainer.motion_count == 1 then
            local motion_elapsed = current_frame - late_cancel_trainer.motion_start_frame
            
            if motion_elapsed < late_cancel_trainer.config.MOTION_INPUT_WINDOW then
                if late_cancel_trainer.motion_type == "QCF" then
                    local detected, _ = detect_qcf(true)
                    if detected then
                        register_second_motion("QCF")
                    end
                elseif late_cancel_trainer.motion_type == "QCB" then
                    local detected, _ = detect_qcb(true)
                    if detected then
                        register_second_motion("QCB")
                    end
                end
            else
                local qcf_detected, _ = detect_qcf(true)
                local qcb_detected, _ = detect_qcb(true)
                
                if (late_cancel_trainer.motion_type == "QCF" and qcf_detected) or
                   (late_cancel_trainer.motion_type == "QCB" and qcb_detected) then
                    table.insert(late_cancel_trainer.messages, "    ✗ Too slow between motions!")
                    late_cancel_trainer.direction_buffer = {}
                end
            end
        end
        
        -- Check completion
        if late_cancel_trainer.motion_count == 2 and #late_cancel_trainer.kick_presses > 0 then
            process_results()
            reset_round()
        elseif elapsed_frames > 120 then
            handle_timeout()
            reset_round()
        end
    end
    
    -- Countdown result display
    if late_cancel_trainer.show_result_frames > 0 then
        late_cancel_trainer.show_result_frames = late_cancel_trainer.show_result_frames - 1
        if late_cancel_trainer.show_result_frames == 0 then
            late_cancel_trainer.result_message = ""
        end
    end
end

-- ============================================================================
-- DISPLAY FUNCTION (called from main script)
-- ============================================================================

function draw_late_cancel_trainer()
    -- Check if enabled via menu (training_settings is a global from main script)
    if not training_settings or not training_settings.late_cancel_trainer_enabled then
        return
    end
    
    local y = 50  -- Position higher on screen for better visibility
    local line_height = 10
    
    -- Title
    gui.text(10, y, "LATE CANCEL TRAINER")
    y = y + line_height + 2
    
    -- Target window
    local cfg = late_cancel_trainer.config
    gui.text(10, y, "Target: Frames " .. cfg.LATE_CANCEL_START_FRAME .. "-" .. cfg.LATE_CANCEL_END_FRAME)
    y = y + line_height
    
    -- Messages
    for _, msg in ipairs(late_cancel_trainer.messages) do
        gui.text(10, y, msg)
        y = y + line_height
    end
    
    -- Result
    if late_cancel_trainer.result_message ~= "" then
        y = y + 2
        for line in late_cancel_trainer.result_message:gmatch("[^\n]+") do
            gui.text(10, y, line)
            y = y + line_height
        end
    end
    
    -- Statistics
    y = y + 3
    local success_rate = 0
    if late_cancel_trainer.stats.attempts > 0 then
        success_rate = (late_cancel_trainer.stats.perfect / late_cancel_trainer.stats.attempts) * 100
    end
    
    local stats_str = string.format("Stats: %dP / %dE / %dL / %dF | Success: %.1f%%",
        late_cancel_trainer.stats.perfect,
        late_cancel_trainer.stats.early,
        late_cancel_trainer.stats.late,
        late_cancel_trainer.stats.failed,
        success_rate)
    
    gui.text(10, y, stats_str)
end

-- Initialize
late_cancel_trainer.messages = {"Press crMK to start"}

print("Late Cancel Trainer module loaded!")
