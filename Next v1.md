### **Product Name**

**Next**

### **AI Companion**

**Sage**

### **Product Category**

AI-assisted behavioral focus system

### **Core Idea**

Next reduces overwhelm by replacing traditional task lists with **one single next action**, delivered conversationally by Sage.

The system focuses on **action initiation**, the hardest step for most users.

### **Primary Value**

Instead of showing everything that needs to be done, Next answers only one question:

“What is the next thing I should do?”

---

# **2\. Target Users**

### **Primary Users**

People who struggle with:

* overwhelm

* disorganization

* low motivation

* task initiation

Examples:

* students

* ADHD-leaning users

* burnout professionals

* people who hate productivity apps

### **Secondary Users**

* knowledge workers

* creatives

* entrepreneurs managing many tasks

---

# **3\. Core Product Philosophy**

### **Behavioral Principles**

1. **Reduce cognitive load**

2. **Shrink tasks to reduce resistance**

3. **Never punish missed days**

4. **Always offer achievable actions**

5. **Encourage momentum**

---

### **Anti-Goals**

Next will **NOT** include:

* large dashboards

* task lists by default

* productivity metrics

* gamification

* streak pressure

* notifications spam

---

# **4\. Core User Experience**

## **App Launch State**

User opens Next and sees:

`Next`

`Write 3 bullet points for your essay.`

`[Start]`

`Estimated: 20 minutes`

Below:

`Done      Not Now`

Minimal interface.

No clutter.

---

# **5\. Primary Features (v1)**

## **Feature 1 — Goal Input**

User can add goals via:

* voice

* text

Example:

“Write my history paper”

---

## **Feature 2 — AI Task Decomposition (Sage)**

Sage breaks the goal into **micro tasks**.

Example output:

`1 Research 3 sources`  
`2 Write introduction outline`  
`3 Draft first section`  
`4 Draft second section`  
`5 Edit paper`

Each step estimated:

* 10–40 minutes

---

## **Feature 3 — One-Task System**

Only **one task visible** at any time.

Example:

`Next Task`

`Write an outline for the introduction.`

`Time: ~20 min`

---

## **Feature 4 — Resistance Detection**

User options:

`Done`  
`Not Now`  
`Too Big`

System response:

| User Action | System Behavior |
| ----- | ----- |
| Done | move to next task |
| Not Now | shrink task |
| Too Big | break into smaller steps |

---

## **Feature 5 — Task Shrinking Logic**

Example:

Original task:

Write introduction outline

Shrink 1:

Write 3 bullet points

Shrink 2:

Write one bullet point

Shrink 3:

Open the document

---

## **Feature 6 — Daily Energy Check**

Morning prompt:

“How’s your energy today?”

Options:

* Low

* Medium

* High

Impact:

| Energy | Task Size |
| ----- | ----- |
| Low | micro tasks |
| Medium | normal |
| High | longer tasks |

---

## **Feature 7 — Daily Reflection**

Evening:

`Today you completed 2 tasks.`

`Anything urgent for tomorrow?`

Simple.

---

# **6\. Interface Design**

### **Design Philosophy**

Minimal  
 Dark  
 Calm  
 No distractions

---

## **Color Palette**

Background

`#1C1C1E`

Text

`#FFFFFF`

Accent (sage green)

`#8FAF9A`

---

## **UI Layout**

`--------------------------------`  
           `NEXT`  
`--------------------------------`

`Write 3 bullet points`  
`for your essay`

`Estimated: 20 min`

`[Start]`

`--------------------------------`  
`Done        Not Now`  
`--------------------------------`

---

# **7\. Technical Architecture**

## **Frontend**

iOS app built with:

* SwiftUI

* Xcode

Core components:

`App`  
`HomeView`  
`VoiceInputView`  
`TaskManager`  
`SageAIService`

---

## **Backend**

Simple architecture:

`iPhone App`  
    `|`  
`API Layer`  
    `|`  
`LLM Provider`  
    `|`  
`Database`

---

### **Backend Tools**

Suggested stack:

| Component | Tool |
| ----- | ----- |
| Auth | Firebase |
| Database | Firestore |
| AI API | OpenAI |
| Hosting | Firebase |

---

# **8\. Data Model**

### **User**

`User`  
`id`  
`energyLevel`  
`preferences`

---

### **Goal**

`Goal`  
`id`  
`title`  
`createdDate`  
`status`

---

### **Task**

`Task`  
`id`  
`goalId`  
`title`  
`estimatedTime`  
`difficultyLevel`  
`status`

---

# **9\. Behavioral Algorithms**

## **Task Selection Algorithm**

Inputs:

* deadline

* energy level

* completion rate

* time availability

Pseudo logic:

`select highest priority task`  
`adjust size based on energy`  
`check resistance history`  
`serve smallest viable action`

---

# **10\. Metrics for Success**

Track:

| Metric | Target |
| ----- | ----- |
| 7-day retention | 40% |
| daily task completion | 1–3 |
| daily open rate | \>60% |

---

