# ATS005 - LFCS: Users and Groups

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

Welcome to **ATS005**, a comprehensive, free training curriculum designed to help you fully master and pass the **Users and Groups** domain of the **Linux Foundation Certified System Administrator (LFCS)** exam.

Users and Groups represents **10% of the total LFCS exam weight**. This repository bridges theoretical identity and access-control concepts with real-world, command-line muscle memory, transforming you from a Linux beginner into a confident systems administrator.

---

## The Symmetrical 1:1:1 Learning Framework

To make learning intuitive, digestible, and robust, this curriculum is built around a symmetrical **1:1:1 educational architecture**:

1.  **The Textbook Lesson (`sections/section-XXX/module-YY/`):** a short landing page (`course.md`) and a few short parts (`course-0N-*.md`) written in plain English, with space analogies, real commands and their output, diagrams, and a hands-on playground machine for every module.
2.  **The Interactive Quiz (`sections/section-XXX/quiz.yaml`):** A scenario-based theoretical knowledge check testing diagnostic reasoning, with an explanation for every answer option.
3.  **The Dedicated Laboratory (`labs/lab-XXX/`):** A virtual machine sandbox environment launched instantly via the `astrona` CLI where you must solve practical identity and access-control objectives and validate your system states using automated testing scripts.

---

## Complete Curriculum & Lab Mapping

The training series is divided into **4 main sections** containing **14 highly focused modules**, **14 targeted lab sandboxes**, and **4 comprehensive Section Capstone Challenges**:

| Section & Domain | Module & Chapter Reader | Practice Lab Sandbox | astrona CLI Run Command |
| :--- | :--- | :--- | :--- |
| **010: Local Account & Group Lifecycle** | [M1: User & Group Account Management](sections/section-010/module-01/course.md) | [lab-011](labs/lab-011) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-011` |
| | [M2: Group Lifecycle Management](sections/section-010/module-02/course.md) | [lab-012](labs/lab-012) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-012` |
| | [M3: Account Defaults, Aging & Locking](sections/section-010/module-03/course.md) | [lab-013](labs/lab-013) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-013` |
| | [M4: Sudoers Drop-ins, Aliases & Group Rules](sections/section-010/module-04/course.md) | [lab-014](labs/lab-014) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-014` |
| | **Section Capstone Challenge** | **[lab-010](labs/lab-010)** | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-010` |
| **020: Access Control & Resource Limits** | [M1: POSIX Access Control Lists](sections/section-020/module-01/course.md) | [lab-021](labs/lab-021) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-021` |
| | [M2: PAM Resource Limits & maxlogins](sections/section-020/module-02/course.md) | [lab-022](labs/lab-022) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-022` |
| | [M3: Resource Limits For Services And Users With systemd](sections/section-020/module-03/course.md) | [lab-023](labs/lab-023) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-023` |
| | [M4: ACLs On Whole Trees](sections/section-020/module-04/course.md) | [lab-024](labs/lab-024) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-024` |
| | **Section Capstone Challenge** | **[lab-020](labs/lab-020)** | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-020` |
| **030: Shell Environment, Profiles & PATH** | [M1: Environment Profiles](sections/section-030/module-01/course.md) | [lab-031](labs/lab-031) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-031` |
| | [M2: Extending PATH Safely](sections/section-030/module-02/course.md) | [lab-032](labs/lab-032) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-032` |
| | **Section Capstone Challenge** | **[lab-030](labs/lab-030)** | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-030` |
| **040: Centralized Identity with LDAP** | [M1: LDAP Server Install & TLS](sections/section-040/module-01/course.md) | [lab-041](labs/lab-041) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-041` |
| | [M2: LDAP Population & TLS Bind Verification](sections/section-040/module-02/course.md) | [lab-042](labs/lab-042) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-042` |
| | [M3: LDAP Client Integration with SSSD](sections/section-040/module-03/course.md) | [lab-043](labs/lab-043) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-043` |
| | [M4: Home Directories For Directory Users](sections/section-040/module-04/course.md) | [lab-044](labs/lab-044) | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-044` |
| | **Section Capstone Challenge** | **[lab-040](labs/lab-040)** | `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-040` |

---

## How to Navigate This Course

To get the most out of this course, follow these steps:

1.  **Open a section:** go into a section folder, such as `sections/section-010/`, and read its `README.md` for an overview of the section and its modules.
2.  **Start the module's playground:** every module's landing page (`module-0N/course.md`) lists its goals, what is in its playground, and the order of its parts. Start the playground with the `astrona run` command for that module and keep it open while you read.
3.  **Read the parts in order:** each module is split into short parts (`course-01-*.md`, `course-02-*.md` and so on). Each part takes about 15 minutes with the playground and ends with its common pitfalls.
4.  **Fly the mission:** the part that finishes a skill ends with a graded mission (`lab-011`, `lab-012` and so on). Run it, solve it on your own, and send it for grading with `astrona submit`.
5.  **Check yourself:** each module's wrap-up page recaps every part, lists the missions, and asks a few questions to check yourself.
6.  **Test your troubleshooting:** take the section quiz (`quiz.yaml`) and answer its scenario questions. Read the explanation for every option.
7.  **Take the capstone:** each section ends with a capstone lab (`lab-010`, `lab-020` and so on) that combines every module of the section on one machine.
8.  **Simulate the exam:** when you have finished all 14 modules, take **`sections/final-domain-quiz.yaml`**, the final 26-question, closed-book quiz within 30 minutes.

---

## Pure-Linux Administrative Focus

This curriculum is designed with strict educational boundaries. To align perfectly with the off-grid, host-level environment of the practical LFCS exam, **all modules and labs focus exclusively on standard host-level Linux system administration.** There are no Kubernetes, container, or cloud-native concepts introduced, allowing you to master core operating system concepts with zero external noise.

---

## Support This Project

ATS005 is free LFCS training material. If it helped you on your administrative journey, consider supporting ongoing work and resource development via [Liberapay](https://liberapay.com/Astrona.io).
