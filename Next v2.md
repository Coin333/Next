# **NEXT v2 — PRODUCT REQUIREMENTS DOCUMENT**

## **1\. Product Overview**

### **Product Name**

**Next**

### **AI Companion**

**Sage**

### **Product Category**

Voice-first AI behavioral assistant

### **Product Vision**

Next helps users move forward through life by presenting **one manageable next action at a time**, guided by a conversational AI assistant.

### **Core Principle**

Users interact with Sage primarily through **voice conversation**.

Unlike traditional AI chat interfaces:

* Spoken words are **not displayed as text transcripts**

* The interface stays minimal

* The experience feels like talking to a calm guide

---

# **2\. Key Differences from Next v1**

| Feature | v1 | v2 |
| ----- | ----- | ----- |
| UI | basic minimal screen | voice-first interface |
| Conversation | simple prompts | multi-turn conversations |
| Task generation | single prompt | contextual decomposition |
| Text display | visible text prompts | speech only |
| AI memory | minimal | structured context memory |
| Conversation handling | simple | conversational pipeline |

---

# **3\. Target User**

Primary users:

* overwhelmed students

* ADHD-leaning individuals

* professionals with chaotic schedules

* creatives with large projects

Pain points:

* task initiation difficulty

* overwhelming to-do lists

* mental clutter

* low motivation cycles

---

# **4\. Core Experience**

### **Core Interaction**

User unlocks phone and opens Next.

Screen:

`Next`

`Ready when you are.`

`[TAP TO SPEAK]`

User speaks:

“I need to finish my research paper and prepare for my presentation.”

Sage responds verbally:

“Let’s break that down. I’ll start with something small.”

The AI processes the input, decomposes the goal, and assigns the next task.

User never sees the raw conversation text.

---

# **5\. UX Philosophy**

### **Minimal Cognitive Load**

The interface should feel like:

* talking to a thoughtful person

* not using a software tool

### **No Visible Transcript**

Speech from the user:

* processed silently

* never shown on screen

AI responses:

* spoken aloud

* optionally summarized visually in short phrases

Example:

AI says:

“Start by opening your research notes.”

Screen may show:

`Next`

`Open your research notes.`

But **never show the user’s spoken words**.

---

# **6\. Voice Conversation Architecture**

The conversation system operates as a pipeline:

`User Voice`  
   `↓`  
`Speech Recognition`  
   `↓`  
`Intent Parsing`  
   `↓`  
`Conversation Context Builder`  
   `↓`  
`AI Prompt Generation`  
   `↓`  
`AI Response`  
   `↓`  
`Speech Synthesis`

---

# **7\. AI Conversation Engine (Sage)**

Sage must support:

### **Conversation Goals**

1. understand user goals

2. decompose large goals

3. assign tasks

4. detect resistance

5. shrink tasks

6. adjust based on energy

---

# **8\. AI Prompt System**

Next v2 uses **multiple prompts**, not a single one.

---

## **Prompt Type 1 — Goal Decomposition**

Input:

`User statement: "Finish my biology project and study for my exam"`

Prompt:

`You are Sage, the AI inside the app Next.`

`Break the user's goal into actionable tasks.`

`Rules:`  
`- tasks must take 10–40 minutes`  
`- use clear action verbs`  
`- no motivational language`  
`- return structured JSON`

`User goal:`  
`{user_input}`

Example output:

`[`  
`{"task":"review biology notes","time":20},`  
`{"task":"create outline for project","time":25},`  
`{"task":"study chapter 3","time":30}`  
`]`

---

## **Prompt Type 2 — Task Shrinking**

When user resists:

`User says: "I don't want to do that right now"`

Prompt:

`Rewrite this task into a smaller step that takes under 10 minutes.`

`Task: {current_task}`

Example output:

`Open biology notes and read the first paragraph.`

---

## **Prompt Type 3 — Next Task Selection**

Prompt:

`User energy level: {energy}`  
`Remaining tasks: {tasks}`

`Choose the best next task.`  
`Return one task.`

---

## **Prompt Type 4 — Conversational Response**

Prompt:

`User message: {input}`

`Respond as Sage:`  
`- calm`  
`- concise`  
`- supportive`  
`- no hype`

---

# **9\. API Integration**

The system sends prompts to an AI provider such as **OpenAI**.

### **API Key Setup**

Example placeholder:

`API_KEY = "YOUR_API_KEY_HERE"`

In production this should be stored securely.

---

# **10\. Example API Request**

`POST https://api.openai.com/v1/chat/completions`

Headers:

`Authorization: Bearer YOUR_API_KEY`  
`Content-Type: application/json`

Body:

`{`  
 `"model":"gpt-4o-mini",`  
 `"messages":[`  
  `{"role":"system","content":"You are Sage..."},`  
  `{"role":"user","content":"Break this goal into tasks: finish research paper"}`  
 `]`  
`}`

---

# **11\. iOS Technical Architecture**

Platform:

* Swift

* SwiftUI

* Xcode

---

### **Core Modules**

`NextApp`  
`VoiceEngine`  
`ConversationManager`  
`SageService`  
`TaskManager`  
`MemoryStore`  
`UIController`

---

# **12\. Voice Input System**

Use Apple Speech framework.

Flow:

`User taps microphone`  
`Speech recognition starts`  
`Speech converted to text`  
`Text passed to conversation engine`

---

# **13\. Voice Output**

Use:

`AVSpeechSynthesizer`

Example:

`let utterance = AVSpeechUtterance(string: response)`  
`speechSynthesizer.speak(utterance)`

---

# **14\. Conversation Memory**

Sage should remember:

* recent user goals

* unfinished tasks

* user resistance patterns

* energy patterns

Data stored locally.

Example:

`UserProfile`  
`Goals`  
`TaskHistory`  
`ConversationContext`

---

# **15\. Task Engine**

The task engine handles:

* priority

* shrinking

* task sequencing

Algorithm:

`select highest priority task`  
`adjust size by energy`  
`check resistance history`  
`serve smallest viable action`

---

# **16\. Interface Design**

### **Screen 1 — Idle**

`Next`

`Ready when you are.`

`[TAP TO SPEAK]`

---

### **Screen 2 — Listening**

`Next`

`Listening…`

Wave animation optional.

---

### **Screen 3 — Task**

`Next`

`Open your research notes.`

`[Done]   [Not Now]`

---

# **17\. Notification Philosophy**

Notifications must be minimal.

Allowed:

* morning check-in

* scheduled task reminder

Forbidden:

* repeated alerts

* guilt messages

---

# **18\. Data Privacy**

User speech is:

* processed via API

* not stored unless required for context

* encrypted in transit

---

# **19\. Success Metrics**

Key metrics:

| Metric | Target |
| ----- | ----- |
| 7-day retention | 40% |
| daily tasks completed | 2 |
| conversation sessions/day | 3 |

---

# **20\. Roadmap Beyond v2**

Potential upgrades:

* emotional tone detection

* Apple Watch integration

* lock-screen widgets

* long-term goal planning

* calendar awareness

---

# **Final Note**

The biggest design principle:

Next should feel like **talking to a calm mentor**, not operating software.

# **APPENDIX A — SAGE PROMPT STACK (NEXT v2)**

## **Overview**

Sage uses a **multi-stage prompt pipeline** instead of a single prompt.  
 This approach improves reliability and allows each AI task to focus on a single responsibility.

Conversation pipeline:

`User Voice`  
   `↓`  
`Speech → Text`  
   `↓`  
`Intent Analysis Prompt`  
   `↓`  
`Goal Decomposition Prompt`  
   `↓`  
`Task Planning Prompt`  
   `↓`  
`Next Task Selection Prompt`  
   `↓`  
`Response Generation Prompt`  
   `↓`  
`Speech Output`

Each stage uses a specialized prompt.

---

# **1\. Master System Prompt**

This prompt is attached to **every AI request** to ensure Sage maintains consistent behavior.

### **Prompt**

`You are Sage, the AI guide inside an app called Next.`

`Your purpose is to help users make progress without overwhelming them.`

`Your communication style:`  
`- calm`  
`- concise`  
`- supportive but not enthusiastic`  
`- grounded and practical`

`Rules:`  
`- Never overwhelm the user`  
`- Break goals into small actionable steps`  
`- Tasks should usually take between 10 and 40 minutes`  
`- If a user expresses resistance, shrink the task`  
`- Avoid motivational speeches`  
`- Avoid productivity clichés`  
`- Use clear action verbs`

`Behavior constraints:`  
`- No guilt-based language`  
`- No pressure or urgency`  
`- No judgment`  
`- Focus only on the next step`

`The system shows only one task to the user at a time.`

`All structured responses must be returned in valid JSON.`

---

# **2\. Intent Analysis Prompt**

Purpose: determine **what the user is trying to do**.

Example user voice input:

“I need to finish my chemistry project and study for my math test.”

### **Prompt**

`Analyze the user's statement and determine their intent.`

`User statement:`  
`{USER_INPUT}`

`Return JSON with:`

`{`  
 `"intent": "",`  
 `"goals": [],`  
 `"urgency_level": "",`  
 `"complexity": ""`  
`}`

`Intent categories may include:`  
`- planning`  
`- goal creation`  
`- task completion`  
`- resistance`  
`- reflection`  
`- general conversation`

---

# **3\. Goal Decomposition Prompt**

Purpose: break a user goal into manageable tasks.

### **Prompt**

`You are Sage.`

`Break the following goal into actionable tasks.`

`Rules:`  
`- tasks must take between 10 and 40 minutes`  
`- use simple action verbs`  
`- tasks should be concrete`  
`- do not include motivational language`  
`- tasks must be sequential where possible`

`Goal:`  
`{GOAL_TEXT}`

`Return JSON:`

`{`  
 `"tasks":[`  
  `{"task":"", "estimated_minutes":0},`  
  `{"task":"", "estimated_minutes":0}`  
 `]`  
`}`

---

# **4\. Task Shrinking Prompt**

Purpose: reduce task size when user hesitates.

Trigger conditions:

* user says “not now”

* user says task is too big

* user delays repeatedly

### **Prompt**

`Rewrite the following task into a smaller step.`

`Rules:`  
`- task must take under 10 minutes`  
`- keep the task meaningful`  
`- avoid vague instructions`

`Original task:`  
`{CURRENT_TASK}`

`Return JSON:`

`{`  
 `"smaller_task":""`  
`}`

---

# **5\. Task Prioritization Prompt**

Purpose: determine which task should be presented next.

Inputs include:

* energy level

* deadlines

* task size

* task order

### **Prompt**

`Select the best next task.`

`User energy level: {ENERGY}`  
`Remaining tasks:`  
`{TASK_LIST}`

`Rules:`  
`- choose the smallest useful task`  
`- respect task order if logical`  
`- if energy is low choose easier tasks`

`Return JSON:`

`{`  
 `"next_task":"",`  
 `"estimated_minutes":0`  
`}`

---

# **6\. Conversational Response Prompt**

Purpose: generate the **spoken response from Sage**.

### **Prompt**

`Generate Sage's spoken response.`

`User input:`  
`{USER_INPUT}`

`Context:`  
`{CONTEXT}`

`Rules:`  
`- speak naturally`  
`- maximum 2 sentences`  
`- calm tone`  
`- no motivational language`

`Return JSON:`

`{`  
 `"speech":""`  
`}`

---

# **7\. Daily Planning Prompt**

Used during morning check-in.

### **Prompt**

`Plan the user's focus for today.`

`User goals:`  
`{GOALS}`

`Energy level:`  
`{ENERGY}`

`Rules:`  
`- choose only a few tasks`  
`- avoid overload`  
`- prioritize meaningful progress`

`Return JSON:`

`{`  
 `"recommended_tasks":[]`  
`}`

---

# **8\. Daily Reflection Prompt**

Used during evening check-in.

### **Prompt**

`Summarize the user's progress today.`

`Completed tasks:`  
`{COMPLETED_TASKS}`

`Remaining tasks:`  
`{REMAINING_TASKS}`

`Return JSON:`

`{`  
 `"summary":"",`  
 `"adjustment_suggestion":""`  
`}`

---

# **9\. Conversation Memory Prompt**

Purpose: update long-term context.

### **Prompt**

`Extract important information from this conversation.`

`Conversation:`  
`{CONVERSATION_TEXT}`

`Return JSON:`

`{`  
 `"new_goals":[],`  
 `"completed_tasks":[],`  
 `"user_preferences":[],`  
 `"emotional_signals":[]`  
`}`

---

# **10\. Safety / Constraint Prompt**

Ensures Sage avoids harmful advice.

### **Prompt**

`Review the following AI response.`

`Response:`  
`{AI_RESPONSE}`

`Check that it follows these rules:`  
`- no harmful instructions`  
`- no medical or legal advice`  
`- no psychological diagnosis`

`Return JSON:`

`{`  
 `"approved":true,`  
 `"reason":""`  
`}`

---

# **Prompt Execution Flow**

Typical interaction pipeline:

`User speaks`  
`↓`  
`Intent Analysis`  
`↓`  
`Goal Decomposition (if needed)`  
`↓`  
`Task Prioritization`  
`↓`  
`Response Generation`  
`↓`  
`Speech Output`

---

# **Prompt Performance Goals**

| Metric | Target |
| ----- | ----- |
| Task clarity | \>90% user understanding |
| Conversation latency | \<2 seconds |
| Task completion success | \>70% |

---

# **Design Principle**

The prompt stack exists to ensure Sage behaves like a **structured cognitive assistant**, not a free-form chatbot.

This architecture keeps the AI:

* predictable

* safe

* focused on action

# **Appendix B — User API Key Configuration**

## **Overview**

Next v2 allows users to supply their **own AI API key** for Sage. This enables the application to communicate with external AI services such as models provided by **OpenAI** without the application distributing a shared key.

This design provides several advantages:

* prevents centralized API costs during early development

* avoids API key exposure inside the application bundle

* allows advanced users to choose their own AI provider

* simplifies developer testing during early builds

User-supplied API keys are stored locally and securely using the **iOS Keychain system**.

---

# **B1. Configuration Flow**

The API key setup occurs during **first launch** or when the user manually configures it in settings.

### **First Launch Flow**

`Launch App`  
 `↓`  
`API Key Check`  
 `↓`  
`Key Missing`  
 `↓`  
`Display Setup Screen`  
 `↓`  
`User Enters API Key`  
 `↓`  
`Validate Key`  
 `↓`  
`Save to Keychain`  
 `↓`  
`Enable Sage`

---

# **B2. Setup Screen**

The API configuration screen is intentionally simple.

Example UI:

`Next Setup`

`To enable Sage, enter your AI API key.`

`[ API Key Field ]`

`Learn how to get a key`

`[Save Key]`

Design principles:

* minimal instructions

* no overwhelming information

* optional help link

---

# **B3. API Key Format**

Keys typically resemble:

`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

Validation checks should confirm:

* minimum length

* valid prefix

* no whitespace

Example validation rules:

`length > 30`  
`startsWith "sk-"`

These checks only verify formatting, not authorization.

---

# **B4. Secure Storage**

API keys must **never be stored in plain text** within the app.

Instead, the key should be stored using the iOS **Keychain Services API**.

Advantages of Keychain:

* encrypted storage

* protected by device security

* not accessible to other apps

* persists across app launches

---

### **Keychain Storage Identifier**

`service = "NextAIKey"`  
`account = "UserAPIKey"`

---

### **Example Keychain Save Logic**

`KeychainManager.save(`  
 `key: "UserAPIKey",`  
 `value: apiKey`  
`)`

---

# **B5. Retrieval at Runtime**

When Sage needs to send a request to the AI service, the application retrieves the key from Keychain.

Flow:

`Conversation Manager`  
 `↓`  
`Sage API Manager`  
 `↓`  
`Retrieve API Key`  
 `↓`  
`Attach Authorization Header`  
 `↓`  
`Send AI Request`

Example HTTP header:

`Authorization: Bearer USER_API_KEY`

---

# **B6. API Key Editing**

Users must be able to update their key.

Settings screen option:

`Settings`

`AI Configuration`

`Current Key: ************`  
`[Change API Key]`

Updating the key will:

1. delete existing key from Keychain

2. save the new key

3. restart Sage service

---

# **B7. API Key Validation**

To verify the key works, the system sends a **lightweight test request**.

Example test prompt:

`Respond with the word "ready".`

Expected response:

`ready`

If the API request fails, the user receives an error.

Example error message:

`The API key could not be verified.`  
`Please check the key and try again.`

---

# **B8. Error Handling**

Common failure scenarios:

| Error | Cause |
| ----- | ----- |
| invalid key | incorrect API key |
| rate limit | too many requests |
| network error | connectivity issue |

User-facing messages should remain simple.

Example:

`Sage couldn't connect to the AI service.`  
`Please check your key or internet connection.`

---

# **B9. Developer Mode**

During development, the application may optionally allow a **hardcoded development key** for faster testing.

Example:

`if developerMode == true {`  
 `useDevAPIKey()`  
`}`

This must be **disabled in production builds**.

---

# **B10. Security Considerations**

To prevent misuse:

* API keys must not be logged

* keys must never appear in analytics

* keys must not be exposed in crash reports

* requests should use HTTPS only

Additional recommendation:

Future versions should route requests through a **secure backend proxy** rather than direct API calls.

Architecture:

`Next App`  
 `↓`  
`Next Backend`  
 `↓`  
`AI Provider`

This approach allows:

* usage monitoring

* abuse prevention

* improved security

---

# **B11. Future Improvements**

Possible upgrades to API configuration:

### **Multi-Provider Support**

Allow users to choose between AI providers.

Example options:

`AI Provider`  
`○ OpenAI`  
`○ Anthropic`  
`○ Local Model`

---

### **Usage Monitoring**

Users may optionally see their token usage.

Example display:

`AI Usage This Month`  
`Requests: 1,245`  
`Estimated Cost: $2.18`

---

# **B12. Design Philosophy**

Allowing user-supplied API keys aligns with the development philosophy of Next:

* flexible

* developer friendly

* cost-efficient during early stages

This approach enables rapid experimentation with Sage while keeping the application architecture simple and secure.

# **Appendix C — Voice Engine Architecture**

## **Overview**

Next v2 is designed as a **voice-first AI assistant**. Users interact with Sage primarily through speech rather than text. The voice engine enables natural conversational interaction while preserving the application's minimalist interface.

The voice system must support:

* speech recognition

* real-time listening

* AI processing

* speech synthesis

The system will be implemented using Apple-native frameworks available in **SwiftUI** applications built in **Xcode**.

---

# **C1. Voice Interaction Principles**

The voice system should follow these principles:

### **Minimal Friction**

Users should feel like they are **speaking to a person**, not operating a device.

### **No Visible Transcript**

User speech is processed internally but **not shown as text on screen**.

This prevents cognitive overload and maintains the minimalist design philosophy.

### **Conversational Rhythm**

Sage should respond naturally with slight pauses between speaking and listening.

---

# **C2. Voice Interaction Flow**

A typical conversation cycle:

`User taps microphone`  
 `↓`  
`Speech recognition begins`  
 `↓`  
`Speech converted to text`  
 `↓`  
`Text sent to Sage AI pipeline`  
 `↓`  
`AI generates response`  
 `↓`  
`Response converted to speech`  
 `↓`  
`Sage speaks response`  
 `↓`  
`System waits for next input`

---

# **C3. Voice System Components**

The voice engine contains four core modules.

`VoiceEngine`  
`SpeechRecognizer`  
`SpeechProcessor`  
`SpeechSynthesizer`  
`ConversationController`

Each module is responsible for a specific stage in the pipeline.

---

# **C4. Speech Recognition**

Speech recognition converts spoken input into text that can be processed by the AI system.

This is implemented using Apple's **Speech Framework**.

Capabilities include:

* real-time transcription

* background listening

* language detection

* partial result updates

Typical recognition flow:

`Start listening`  
 `↓`  
`Capture microphone audio`  
 `↓`  
`Convert audio to text`  
 `↓`  
`Send text to conversation manager`

---

# **C5. Listening States**

The voice system should maintain clear internal states.

Possible states include:

| State | Description |
| ----- | ----- |
| idle | waiting for user |
| listening | recording speech |
| processing | sending data to AI |
| speaking | Sage delivering response |

Only one state should be active at any time.

---

# **C6. Microphone Activation**

Users activate voice input through a simple gesture.

Possible activation methods:

* tap microphone button

* tap center screen

* hold-to-speak

Recommended design:

`Tap → start listening`  
`Tap again → stop listening`

This avoids accidental long recordings.

---

# **C7. Speech Processing**

Once speech is converted to text, the system sends the text to the conversation pipeline.

Processing flow:

`SpeechRecognizer`  
 `↓`  
`Text Input`  
 `↓`  
`Intent Analysis Prompt`  
 `↓`  
`Task Planning Prompt`  
 `↓`  
`Response Generation Prompt`

The processed result is then passed to the speech synthesis engine.

---

# **C8. Speech Synthesis (Sage Voice)**

Sage responses are spoken using Apple’s speech synthesis system.

Key design requirements:

* calm voice

* moderate pace

* neutral tone

The system should avoid overly robotic or overly expressive voices.

Recommended settings:

`speechRate = medium`  
`pitch = slightly lower`  
`volume = normal`

---

# **C9. Interrupt Handling**

Users must be able to interrupt Sage.

Example scenario:

`Sage speaking`  
`User starts speaking`  
 `↓`  
`Speech playback stops`  
 `↓`  
`System switches to listening state`

This behavior makes conversations feel natural.

---

# **C10. Silence Detection**

The voice engine should detect when the user finishes speaking.

Methods include:

* pause detection

* end-of-speech analysis

* timeout threshold

Typical silence timeout:

`1.5 seconds`

After this pause the system assumes the user finished speaking.

---

# **C11. Error Handling**

Voice recognition may fail due to:

* background noise

* unclear speech

* microphone access denied

Example recovery behavior:

`"I didn't catch that. Could you repeat it?"`

Errors should be rare and handled gently.

---

# **C12. Privacy Considerations**

User voice data must be handled carefully.

Guidelines:

* do not permanently store raw audio

* process speech locally when possible

* send only necessary text to AI systems

* always use encrypted connections

---

# **C13. Future Voice Enhancements**

Future versions may include:

### **Continuous Conversation Mode**

Allow users to speak without repeatedly tapping the microphone.

### **Emotional Tone Detection**

Voice analysis could detect user fatigue or stress.

### **Personalized Voice for Sage**

Users could choose different Sage voices.

---

# **Appendix D — Task Decomposition Algorithm**

## **Overview**

The most important feature of Next is the ability to convert **large goals into small, achievable tasks**.

This process is called **task decomposition**.

The goal is to eliminate overwhelm and increase the likelihood that users start tasks.

---

# **D1. Core Principle**

Next never shows users an entire task list.

Instead it shows **only the next actionable step**.

Example:

User goal:

`Finish research paper`

Task decomposition may produce:

`Open research notes`  
`Create outline`  
`Write introduction paragraph`

But the user only sees:

`Open research notes`

---

# **D2. Task Size Rules**

Tasks must follow strict size limits.

| Task Type | Time |
| ----- | ----- |
| micro task | 5–10 minutes |
| standard task | 10–40 minutes |

Large tasks must be broken down further.

---

# **D3. Decomposition Process**

The system follows a structured planning process.

`User goal`  
 `↓`  
`AI decomposition`  
 `↓`  
`Task filtering`  
 `↓`  
`Priority assignment`  
 `↓`  
`Next task selection`

---

# **D4. Task Structure**

Each task must contain:

`task_id`  
`description`  
`estimated_time`  
`priority`  
`status`

Example:

`{`  
 `"task_id": 102,`  
 `"description": "Create outline for research paper",`  
 `"estimated_time": 20,`  
 `"priority": 3,`  
 `"status": "pending"`  
`}`

---

# **D5. Task Prioritization**

Tasks are ranked using a simple scoring model.

Priority factors:

* urgency

* logical order

* user energy level

* past avoidance

Priority score example:

`priority_score =`  
`(urgency × 2) +`  
`(logical_sequence × 2) +`  
`(energy_match)`

The highest score becomes the next task.

---

# **D6. Resistance Detection**

When users resist a task, the system reduces difficulty.

Resistance indicators include:

* user postpones task

* user verbally declines

* repeated skipping

Example:

`Original task:`  
`Write introduction paragraph`

`Reduced task:`  
`Write one sentence for the introduction`

---

# **D7. Task Shrinking Algorithm**

If resistance is detected:

`new_task_time = current_task_time / 2`

Example progression:

`Write essay section (30 min)`  
`↓`  
`Write paragraph (15 min)`  
`↓`  
`Write sentence (5 min)`

---

# **D8. Energy-Aware Task Selection**

Sage adjusts tasks based on user energy.

Example inputs:

`time of day`  
`recent task completion`  
`user self-report`

Low energy → smaller tasks.

High energy → deeper work tasks.

---

# **D9. Task Completion Loop**

When a user completes a task:

`Task marked complete`  
 `↓`  
`Task list updated`  
 `↓`  
`Next task selected`  
 `↓`  
`Sage presents new step`

This loop continues until the goal is finished.

---

# **D10. Daily Planning**

At the beginning of the day Sage prepares a limited plan.

Example:

`Today's focus:`  
`- Review biology notes`  
`- Write project outline`

Only one task is shown at a time.

---

# **D11. Behavioral Reinforcement**

Sage reinforces progress subtly.

Example response:

`"Nice progress. Ready for the next step?"`

Positive reinforcement increases engagement without creating pressure.

---

# **D12. Failure Recovery**

If a user abandons tasks:

`Reset task difficulty`  
 `↓`  
`Return to smallest actionable step`

Example:

`Original goal:`  
`Finish project`

`Reset task:`  
`Open project document`

---

# **D13. Long-Term Goal Tracking**

Goals are stored with progress tracking.

Example structure:

`Goal`  
 `progress_percentage`  
 `tasks_completed`  
 `tasks_remaining`

This allows Sage to measure forward progress without overwhelming the user.

---

# **D14. Algorithm Design Philosophy**

The task engine prioritizes **behavioral success**, not productivity optimization.

Key principles:

* small wins create momentum

* progress reduces anxiety

* visible completion builds motivation

---

# **Final Design Insight**

The combination of **Appendix C (Voice Interaction)** and **Appendix D (Task Decomposition)** defines the core of Next.

Together they enable Sage to function as:

`a calm conversational guide`  
`+`  
`a behavioral task planner`

This is what transforms Next from a typical productivity app into a **true AI companion for forward progress**.

