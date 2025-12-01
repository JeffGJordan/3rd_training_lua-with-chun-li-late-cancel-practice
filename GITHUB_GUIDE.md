# How to Publish Your Fork to GitHub

Since you downloaded the original code as a ZIP file (it's not a git repository yet), here is the easiest way to publish your work as a proper fork.

## Step 1: Fork on GitHub

1.  Log in to [GitHub.com](https://github.com).
2.  Go to the original repository: [https://github.com/Grouflon/3rd_training_lua](https://github.com/Grouflon/3rd_training_lua)
3.  Click the **Fork** button (top right).
4.  This creates a copy of the repo under your account (e.g., `YourUsername/3rd_training_lua`).

## Step 2: Install Git (Required)

It looks like Git is not installed on your computer yet.

1.  **Download Git:** [https://git-scm.com/download/win](https://git-scm.com/download/win)
2.  **Install it:** Run the installer and click "Next" through the options (defaults are fine).
3.  **Restart your terminal:** Close any open command prompts or PowerShell windows so they can see the new installation.

## Step 3: Prepare Your Local Folder

We need to turn your current folder into a git repository and link it to your new fork.

1.  **Open a terminal** (Command Prompt or PowerShell) in your project folder:
    `c:\Users\jeffr\PycharmProjects\PythonProject2\3rd_training_lua-master`

2.  **Initialize Git:**
    ```powershell
    git init
    ```

3.  **Link to your GitHub fork:**
    Replace `YourUsername` with your actual GitHub username:
    ```powershell
    git remote add origin https://github.com/YourUsername/3rd_training_lua.git
    ```

4.  **Align with the original history:**
    ```powershell
    git fetch origin
    git reset --mixed origin/master
    ```
    *(Note: If `origin/master` fails, try `origin/main` - Grouflon uses `master`)*

## Step 4: Commit Your Changes

Now we save your changes (the late cancel trainer, menu updates, etc.).

1.  **Stage all files:**
    ```powershell
    git add .
    ```

2.  **Commit:**
    ```powershell
    git commit -m "Added Chun-Li Late Cancel Trainer with menu integration"
    ```

## Step 5: Push to GitHub

1.  **Upload your code:**
    ```powershell
    git push -u origin master
    ```

---

## Done! 🎉

Your fork is now live at `https://github.com/YourUsername/3rd_training_lua`.
People can download it, and you can even submit a "Pull Request" to Grouflon if you want to share it with the original creator!
