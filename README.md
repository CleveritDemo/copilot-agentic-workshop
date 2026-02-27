<div align="center">
  <img src="./assets/header_eng.png" alt="GitHub Copilot - Adoption Program" width="100%" />

  # GitHub Copilot Agent Capabilities Session

  [![GitHub Copilot](https://img.shields.io/badge/GitHub_Copilot-000000?style=for-the-badge&logo=githubcopilot&logoColor=white)](https://github.com/features/copilot)
  [![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
  [![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
  [![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
</div>

---

**This hands-on training** will help you get familiar with GitHub's powerful agentic tools, such as: **Copilot Coding Agent**, **Custom Agents**, **Agent Skills**, **Mission Control**, and **GitHub Copilot Code Review**; additionally, we will cover custom documentation spaces using **GitHub Copilot Spaces**.

> For more information about these tools, check the official documentation:
>
> - [Coding Agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/use-copilot-agents/coding-agent)
> - [Custom Agents](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents)
> - [Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
> - [Extend Copilot Chat with MCP](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/extend-copilot-chat-with-mcp)
> - [Mission Control](https://github.blog/changelog/2025-10-28-a-mission-control-to-assign-steer-and-track-copilot-coding-agent-tasks/?utm_source=blog-day1-recap-mission-control-cta&utm_medium=blog&utm_campaign=universe25)
> - [Copilot Spaces](https://docs.github.com/en/copilot/how-tos/provide-context/use-copilot-spaces)
> - [Code Review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review)

---

## 📋 Table of Contents

1. [🚀 Run the application](#-run-the-application)
2. [🧠 Step 1. Using Copilot Coding Agent (Part 1)](#-step-1-using-copilot-coding-agent-part-1)
    - [From an Issue](#1-from-an-issue-📝)
    - [From Mission Control](#2-from-mission-control-🎛️)
    - [From the Agents tab](#3-agents-tab-in-the-repository-📂)
    - [Delegating from the IDE](#4-delegating-from-the-ide-💻)
3. [🤖 Custom Agents](#-custom-agents)
4. [🛠️ Agent Skills](#️-agent-skills)
5. [🪐 Step 2. Using GitHub Copilot Spaces](#-step-2-using-github-copilot-spaces)
6. [🧠 Step 3. Using GitHub Copilot Coding Agent (Part 2)](#-step-3-using-github-copilot-coding-agent-part-2)
7. [👀 Step 4. GitHub Copilot Code Review](#-step-4-github-copilot-code-review)

---

## 🚀 Run the application

To get this application up and running, you have two options available:

1.  **Manual Execution:** Check the [about](./about.md) page, where you will find the steps and requirements needed to run this application locally step by step.
2.  **Copilot Agent Assistance:** You can ask the agent to handle the execution. Open the chat in your editor in agent mode and use a prompt like the following:

    > "Analyze the project structure and execute the necessary commands to start the application using Docker Compose."

This is a **Todo-List** application that runs using Docker Compose. It consists of two services:
- **Frontend**: Built with React.
- **Backend**: Built with Node.js and Express.

![Default look](./assets/default.png)
---

## 🧠 Step 1. Using Copilot Coding Agent (Part 1)

The goal is to **change the accent colors** of the Todo-List application.

**Current State:**
![Default look](./assets/default.png)

**Goal:** Change the blue accent color to **dark green**.

### Methods to request changes from the Copilot Coding Agent:

### 1. From an Issue 📝
This is the most structured way. You assign an issue to Copilot, and it handles the rest. **This is the method we will use below.**

### 2. From Mission Control 🎛️
Access [github.com/copilot/agents](https://github.com/copilot/agents) to manage agent sessions globally.

### 3. Agents Tab in the Repository 📂
Start new tasks specific to this repository without creating a formal issue from the **Agents** tab.

### 4. Delegating from the IDE 💻
Ask Copilot directly in VS Code or Visual Studio to perform complex tasks.

---

### **Assign an Issue to Copilot**

1. Go to the **Issues** tab in this repository.

   ![issues](./assets/issues-1.png)

2. Click on **New Issue**.
3. Fill in the **Title** with the precise action:

   ```text
   Modify the accent colors on every single component of the application; the current color is blue, change it from blue to dark green.
   ```

4. Fill in the **Description** with additional context:

   ```text
   Please keep in mind that all changes must be done for both look and feels of the app: dark mode and light mode.
   ```

   **Example:**
   ![Issue](/assets/issues-2.png)

5. In the right sidebar, assign the issue to **GitHub Copilot**.

   ![Copilot-Assign](./assets/copilot-assign.png)

6.  Click on **Submit New Issue**.

> [!NOTE]
> Copilot will open a new Pull Request (Draft), mark it as **Work In Progress (WIP)**, and begin analyzing the task. Notice the 👀 emoji indicating that Copilot is working.

![Assigned issue](./assets/issues-3.png)

---

### **Assign via Mission Control**

1. Go to [github.com/copilot/agents](https://github.com/copilot/agents).
2. Select the repository, the branch, and the agent (Copilot).
3. Use the following prompt:

   ```text
   Add a new feature that allows the user to assign a predefined category to each task at the time of creation.
   The predefined categories are: Low, Medium, and High. This functionality should include a dropdown menu in the task creation form, where the user can select the corresponding category. Additionally, each category should be associated with a specific color to facilitate visual identification in the task list.
   ```

4. Click to assign.

   ![Assigned issue](./assets/assign-task-mission-control.png)

---

### **Assign from the "Agents" tab of the repository**

1. Go to the **Agents** tab in your repository.
2. Create a new task with the following prompt:

   ```text
   Add a new functionality that allows enabling the modification of data for an already created task (title). This functionality should include an edit button next to each task in the list, which when clicked allows the user to modify the task title. Additionally, validation must be implemented to ensure the new title is not empty before saving changes.
   ```

   ![Assigned issue](./assets/agents-tab.png)

---

### 🕵️‍♂️ Real-Time Supervision and Intervention

In both Mission Control and the Agents tab, you have total control:

*   **Session Log:** View actions and commands in real-time.
*   **Human Intervention:** Intervene at any time to give instructions or stop the agent.

---

### Delegating from the IDE

In **VS Code**, select "cloud" in the Copilot chat and use this prompt:

```text
Add functionality that allows the user to search for specific tasks within the current list using a text filter. This functionality should include a search field at the top of the task list, where the user can enter keywords to filter the displayed tasks. The filter should be dynamic, updating the task list in real-time as the user types, and should look for matches in the task titles.
```

![Assigned task](./assets/delegate-task-from-ide.png)

---

## 🤖 Custom Agents

GitHub Copilot allows creating agents with specific skills for your project.

- **What are they?** Versions of the Coding Agent adapted to your standards.
- **Role:** Expert team member in your tools.
- **Efficiency:** One-time configuration, avoids repeating context.

### Creating a Custom Agent (Repository Level):

1. In Copilot Chat, select **Configure Custom Agents...** > **Create new custom agent**.
2. **Scope:** Select **Workspace** (saved in `.github/agents`).
3. **Name:** Assign a name to your agent.

Review the structure in `/agents`. Copy the example agent to `.github/agents` to test it.

**Example Prompt:**
You must select the custom agent in the agent selector before sending the following instruction:

```text
Migrate the current frontend (Vanilla JS) to React with Vite and update the Docker configuration.

Code Tasks:
1. Refactor `frontend/index.html` and `frontend/script.js` into React components (`App`, `TaskList`, `TaskForm`, etc.).
2. Implement state management with Hooks to replicate current CRUD functionality.
3. Reuse `frontend/style.css` to maintain the design.
4. Generate Vite configuration (`vite.config.js`).

Infrastructure Tasks (Docker):
1. Update `frontend/Dockerfile` to use a "multi-stage" build:
   - Stage 1 (Build): Use a Node image to install dependencies and run `npm run build`.
   - Stage 2 (Serve): Use an Nginx image to serve the static files generated in the `dist` folder.
```

---

## 🛠️ Agent Skills

Specialized modules that Copilot activates to solve complex tasks.

- **Locations:** `.github/skills/` (repository) or `~/.copilot/skills/` (global).
- **File:** `SKILL.md` with YAML header and instructions.

**Exercise:**
Check the `skills` folder in the root of the project. It contains an example skill about github issues. Once reviewed, move the `skills` folder to `.github/skills/`.

**Note**: At this point, we will be using the GitHub MCP server to create a GitHub issue directly from the custom agent using the `github-issues` skill. To do this, make sure you have the MCP server configured and that your custom agent has access to this skill. You may be prompted to sign in to GitHub to authenticate and use the MCP server.

use this prompt in VS Code:

```text
Create an issue on github that allows me to add a functionality to view a card or text with the count of pending tasks
```

The agent mode will detect the intent to create an issue and activate the `github-issues` skill to execute this task. You will see that the agent automatically generates the issue with the appropriate structure and format.

---

## 🪐 Step 2. Using GitHub Copilot Spaces

Copilot Spaces centralizes context and documentation for your team.

### 2.1 Create documentation

1. Create a branch: `git checkout -b copilot-spaces-branch`
2. In Copilot Chat (VS Code), use the prompt:

   ```text
   Improve the #about.md file to include advanced project documentation. Include sections indicating: what runtimes and frameworks are used, explain in detail how to run the project and how to access it via the browser. 🌐

   Use technical language targeted at an audience of Developers, Sysadmins, DevOps Engineers, and Cloud Engineers. 🛠️☁️

   Include emojis and icons when necessary. ✨
   ```

3. Accept the changes, commit, and push.

### 2.2 Creating a Copilot Spaces environment

1. Go to [GitHub](https://github.com) > Side Menu > **Copilot** > **Spaces**.
2. Click on **Create space** and complete the data.
3. Add the repository as a source.
4. Ask the space:

   ```text
   How can I run this project and what are the runtimes of copilot-agentic-demo?
   ```

---

## 🧠 Step 3. Using GitHub Copilot Coding Agent (Part 2)

Verify the tasks assigned previously through the different methods (Issue, Mission Control, Agents Tab, IDE).

1. Open the associated Pull Requests for each of the tasks.
2. Review the details and screenshots provided by Copilot.
3. Click **View Session** to see the agent's "step-by-step" and the strategy used.
4. If you are satisfied with the results, Merge the PRs.

![results](./assets/Copilot-Coding-Agent-Results.png)

<div align="center">

If you downloaded the project and ran the application, this is the final result after the Copilot Coding Agent made the requested changes in Step 1.

![final-result](./assets/final-result.png)

</div>

---

## 👀 Step 4. GitHub Copilot Code Review

Automate code review in the SDLC flow.

1. Go to an open Pull Request.
2. Assign the review to **GitHub Copilot**.

![code-reviewer](./assets/copilot-code-reviewer.png)

Copilot will automatically leave comments and suggestions.

---

<div align="center">

**You have reached the end of the training. Congratulations! 💫**

</div>
