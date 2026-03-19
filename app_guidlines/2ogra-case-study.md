# 2ogra Project Brief for Microbus Fare Handling in Egypt

## Executive summary

Microbuses are a dominant, high-frequency transport mode in the Greater Cairo travel ecosystem, and their high-throughput, cash-based fare collection makes “small arithmetic + change-making” a constant operational burden. A policy brief on mobility in Greater Cairo attributes **~63% of daily trips (>500m) in 2014** to microbuses and estimates the informal/semi-formal sector (predominantly microbuses) absorbs **~8.1 million journeys/day**. citeturn5view4turn10view3 This scale means that even tiny reductions in transaction time, disputes, or change shortages compound into meaningful improvements in trip flow and passenger experience.

“2ogra (أجرة)” is proposed as an **offline-first, one-handed, minimal-interaction mobile app** that helps microbus fare collectors (كُمّسري), drivers, and optionally passengers to compute fares and produce **feasible change breakdowns** based on a modeled pocket inventory (“Pocket Mode”), with an optional, explicitly governed rounding/tolerance feature. This matches real fare-handling language where payments are relayed with phrases like “واحد من الخمسة” and “اتنين من الخمسة” and change is requested back (باقي…)—patterns documented in Egyptian Arabic usage guides and widely echoed in lived-experience narratives. citeturn19search14turn2search17

The MVP focuses on speed and reliability: **<1 second** computation, no typing, large buttons, and deterministic change suggestions that respect Egyptian cash denominations (commonly used banknotes include 1, 5, 10, 20, 50, 100, 200 EGP; smaller piastre denominations exist but are less salient in daily “micro” transactions). citeturn0search0 A later roadmap adds speech input (Voice Mode) with Egyptian Arabic transcription support options (e.g., **ar‑EG** in major cloud STT services), presets for common fare phrases (“اتنين من 100”), and optional synchronization/analytics. citeturn14view0turn12search1turn15view0

Key risks are ethical and adoption-related: features must not be perceived as enabling short-changing; battery/latency constraints are strict; and monetization must align with low willingness-to-pay among informal transport workers. Mitigations include **“Fair Mode” defaults**, explicit “rounding policy” disclosure, passenger-facing verification screens, and privacy-by-design (local storage, minimal data collection). Current governmental attention to fare compliance after fuel-price-driven adjustments underscores the importance of transparent, tariff-respecting UX. citeturn17view0turn17view2turn17view1

## Problem statement and context

Microbus fare collection is a high-pressure, real-time activity where multiple cash streams converge in a constrained physical environment: moving vehicle, noise, single-hand operation, and frequent interruptions. The informal sector is explicitly described as shared taxis (microbuses) with typical capacities of **11 or 14 seats**, and the record notes that data about patronage is often fragmented—an operational reality that makes lightweight, field-observed product discovery essential. citeturn5view0turn10view0

At the network level, a World Bank-supported multimodal strategy report produced with entity["organization","Transport for Cairo","mobility ngo, cairo"] mapped **603 unique bus routes** in summer 2019 across entity["state","Giza Governorate","egypt"], entity["city","Cairo","egypt"], and entity["state","Qalyubia Governorate","egypt"], including **360 informal transit routes**. It also reports that informal routes are nearly twice as numerous as formal routes in surveyed areas and can be operationally faster by avoiding highly congested corridors—conditions that increase the tempo of fare interactions and the cost of errors. citeturn5view3turn10view2turn11view1

Fare levels and enforcement are also dynamic. Public-transport fares (including microbuses and minibuses) are frequently adjusted in response to fuel price changes, with governors publishing tariffs, signage, and enforcement mechanisms. For example, in October 2024, reporting on Cairo’s adjustments cited minibus fares around **LE 14** for ordinary routes and **LE 17** for air-conditioned routes (with governorate-specific variation and formal compliance messaging). citeturn17view0 In October 2025, Cairo governorate announcements described **10–15%** increases and listed minibus fares reaching **EGP 18** (ordinary) and **EGP 22** (air-conditioned), with compliance hotlines and inspection campaigns. citeturn17view1turn8view1turn10view4 Immediately prior to this project brief date (2026‑03‑17), Egypt again implemented new fare rates post-fuel adjustment with national-level oversight emphasizing signage and enforcement. citeturn17view2turn0search3

The microbus cash-handling workflow is shaped by how money is physically transferred and linguistically encoded. A practical Egyptian Arabic guide describes the pattern of passing a bill forward while stating “one fare from the five” (واحد من الخمسة) and escalating reminders to return change (باقي…), and also explicitly uses “two fares from the five” (اتنين من الخمسة) when paying for multiple riders. citeturn19search14 This directly generalizes to the commonly understood structure “اتنين من 100” (two fares paid from a 100 note), which also appears repeatedly in Egyptian narratives about “مشكلة الفكة” (lack of change). citeturn2search17turn2search1

image_group{"layout":"carousel","aspect_ratio":"16:9","query":["Egyptian pound banknotes 200 100 50 20 10 5 1","Egyptian pound coins 1 pound 50 piastres 25 piastres","Cairo microbus interior fare passing money","microbus Egypt Toyota Hiace 14 seater interior"],"num_per_query":1}

## Users, personas, and behavioral patterns

The “2ogra” product should be designed for **role fluidity**: in some vehicles the driver collects; in others a fare collector (كُمّسري) manages money; in crowded settings passengers may relay notes and change along the seating line. This matches the documented “money passes forward / change passes back” norm and the need for shouted reminders when change is delayed. citeturn19search14turn2search17

### Personas

**Fare collector (كُمّسري / collector)**  
Primary target user. High-volume, time-critical tasks: tracking who paid, how much was paid, and what change is owed. Operates in noisy, cramped environments where the cost of mistakes is immediate disputes. The broader transport context indicates microbuses are a dominant public transport mode in Greater Cairo and absorb millions of journeys/day, which implies frequent collector-customer interactions. citeturn5view4turn10view3

**Driver (سائق)**  
May act as collector or final authority on fares, stops, and route behavior. Official fare-setting and compliance messages frequently address drivers and route adherence alongside fare compliance, reflecting that drivers are often held accountable. citeturn17view0turn17view2

**Passenger (راكب)**  
Wants speed, fairness, and reduced conflict. Passenger behavior includes participation in money chaining, reminders for change, and reference to official tariffs when disputes occur (governorates explicitly instruct citizens to pay officially announced fares and report violations). citeturn17view0turn19search14

**Conductor (in a broader sense)**  
In some public transport contexts, a conductor collects fares post-boarding, reinforcing that fare-handling can be a distinct operational role, even if microbus practice varies by route and city. citeturn4search18

### Behavioral patterns that matter for product design

Cash remains central to everyday small-ticket transactions, while digital rails are growing fast. Public reporting in late 2025 cited strong growth in digital payments infrastructure (including large numbers of e-wallet transactions and sizeable InstaPay usage), which matters as a “future option,” but does not yet remove the need for robust offline cash workflows in informal transport. citeturn17view3turn10view5

Word-of-mouth and observational learning are relevant: microbus practices (how to pay, what to say, how to request change) are transmitted socially and reinforced by repeated daily exposure; language-learning guides explicitly teach these fare-handling phrases as part of “how to ride.” citeturn19search14turn19search25

Bargaining in the strict pricing sense is constrained by official tariffs and periodic enforcement surges, but “micro-negotiations” happen around change availability: delayed change, partial change, “remind me later,” or informal rounding. Governorate announcements emphasize posting fares and legal action for violations, underlining that any app feature touching rounding must be framed carefully and default to compliance. citeturn17view0turn17view2turn17view1

## User journeys, stories, and workflows

The MVP should model **transactions**, not just arithmetic. Each transaction is: *fare rule* + *riders count* + *payment note(s)* + *(optional) pocket inventory constraints* + *(optional) rounding policy* → *change plan* + *ledger update*.

### Core user stories

**Collector: single passenger with exact/near-exact cash**  
As a collector, I want to enter “1 passenger” and tap “paid 20” with fare “15,” so I immediately see “change 5” and hand back a single 5, without thinking. This addresses time pressure in high-frequency boarding sequences implied by millions of trips and high microbus mode share. citeturn5view4turn10view3turn19search14

**Collector: multiple passengers paying with a large bill (“اتنين من 100”)**  
As a collector, I want a one-tap preset like “2 riders from 100” so I don’t manually compute 2×fare and change, consistent with commonly described fare phrasing and the money relay pattern. citeturn19search14turn2search17turn2search1

**Collector: limited pocket change**  
As a collector, I want the app to suggest only the change I can actually make from my pocket inventory (e.g., I have no 20s), because lack of change triggers confusion and disputes documented as “مشكلة الفكة.” citeturn2search17turn19search14

**Collector: intentional “keep change” / rounding**  
As a collector (or as a driver managing earnings), I may want to apply a consistent rounding policy (e.g., “round down change owed by up to 1 EGP”) and track it transparently so I can reconcile later and avoid ad-hoc disputes—while ensuring the app does not default to short-changing and aligns with heightened fare compliance expectations. citeturn17view0turn17view2turn17view1

**Passenger: verify what’s owed**  
As a passenger, I want to quickly check “2 riders, fare 15, paid 100 → change 70” so disputes can be resolved quickly, consistent with governorate messaging encouraging citizens to adhere to posted fares and report violations. citeturn17view0turn19search14

### Workflow diagrams

The flow below reflects observed “pay forward / change back” dynamics and the need for cash-feasible change plans under speed constraints. citeturn19search14turn11view1

```mermaid
flowchart TD
  A[Start: new fare transaction] --> B[Select fare or route preset]
  B --> C[Select riders count]
  C --> D[Select amount paid (tap banknote)]
  D --> E[Compute total = fare * riders]
  E --> F[Compute change_due = paid - total]
  F --> G{Pocket Mode enabled?}
  G -->|No| H[Suggest minimal-bills change combo (unbounded)]
  G -->|Yes| I[Find best feasible change combo using inventory]
  I --> J{Feasible?}
  J -->|Yes| K[Display combo + update inventory ledger]
  J -->|No| L[Offer options: alternate combo / partial change / IOU / rounding within policy]
  H --> M[Confirm transaction]
  K --> M
  L --> M
  M --> N[End / next passenger]
```

A companion sequence view illustrates “collector + passenger” interaction around “two from 100,” including the option to announce “change coming back” (باقي…) as per common practice. citeturn19search14turn2search17

```mermaid
sequenceDiagram
  participant P as Passenger
  participant C as Collector
  participant App as 2ogra App

  P->>C: "اتنين من 100" + hands 100 note
  C->>App: Tap preset "2 riders from 100"
  App->>App: total = 2*fare; change_due = 100-total
  App-->>C: Show change plan (e.g., 50+20) and confidence
  C-->>P: Returns change per plan (or announces delay if needed)
  Note over C,P: If change not possible, App suggests IOU/rounding per policy
```

## Functional requirements and roadmap

The app must support two tightly scoped primary modes: **Collector Mode** (default) and **Passenger Mode** (read-only verification). The roadmap below prioritizes features that directly reduce calculation time, disputes, and the “no change” problem described in user narratives and language guides. citeturn19search14turn2search17

### Feature priority table

| Capability | MVP | Later | Rationale tied to context |
|---|---|---|---|
| Fare input: fixed fare value + quick adjustment | ✅ |  | Fares vary by route and change after fuel price hikes; fast edit is necessary. citeturn17view0turn17view2 |
| Riders count selector (1–14 quick taps) | ✅ |  | Microbuses commonly seat 11–14; UI should match capacity scale. citeturn5view0turn18view2 |
| Payment amount buttons (1,5,10,20,50,100,200) | ✅ |  | Aligns with common banknote denominations used in daily fares. citeturn0search0 |
| Instant compute (total + change) | ✅ |  | Targets error reduction and speed under high-flow conditions. citeturn5view4 |
| Smart Change (unbounded) | ✅ |  | Gives immediate “50+20” breakdown instead of only “70.” |
| Pocket Mode (cash inventory) | ✅ |  | Directly addresses “no change” constraints and “مشكلة الفكة.” citeturn2search17turn19search14 |
| Feasibility fallback: “cannot make change” + options | ✅ |  | Prevents silent failure and reduces disputes. citeturn17view0 |
| One-tap presets (“اتنين من 50/100/200”) | ✅ |  | Mirrors phrase patterns used in payment relay. citeturn19search14turn2search1 |
| Rounding policy (explicit, opt-in, tracked) |  | ✅ | Ethically sensitive; must be introduced carefully with defaults aligning to official tariffs. citeturn17view2turn17view0 |
| Daily ledger: collected, returned, net, discrepancies |  | ✅ | Useful for drivers/collectors and for reconciling “IOU/rounding.” |
| Voice Mode (Arabic STT) for phrases |  | ✅ | Improves speed in noisy environments if accuracy is adequate; needs careful vendor selection. citeturn14view0turn12search1turn12search11 |
| Optional sync (device-to-device / cloud) |  | ✅ | Useful for multi-vehicle fleets; not required for core value. |
| Passenger QR “verify fare” share |  | ✅ | Supports transparency under compliance regimes. citeturn17view0 |

### Detailed MVP functional requirements

**Inputs**
- Fare per rider (EGP), with quick +/- (e.g., +1, +2) to adapt during fare-change periods. citeturn17view2turn17view0  
- Riders count: 1–14 via large tap targets (capacity-aligned). citeturn5view0turn18view2  
- Amount paid: single-tap denominations (1, 5, 10, 20, 50, 100, 200). citeturn0search0  
- Optional: pocket inventory counts per denomination (Pocket Mode). citeturn2search17  

**Outputs**
- Total due = fare × riders.
- Change due = paid − total (with clear negative-state handling: “still owed X”).
- Suggested change breakdown:
  - “Best” option: minimize number of bills/coins.
  - Secondary option: alternative breakdown if the first is infeasible in Pocket Mode.
- “Explain” line showing the mental model: “2 × 15 = 30; 100 paid; change 70.”

**Pocket Mode (cash inventory)**
- User can quickly increment/decrement counts per denomination (with “pocket reset” at start of day).
- Inventory update rule:
  - When a payment is received, the paid denomination is added.
  - When change is given, those denominations are subtracted.
- “Emergency” quick set buttons (e.g., “I have mostly 5s/10s” presets) based on observed reality that change availability varies and can trigger conflict. citeturn2search17turn19search14  

**Offline-first behavior**
- All core calculations and Pocket Mode must operate without network.
- No login required to compute change (frictionless adoption). This is aligned with the informal nature of microbus operations and the need for sub-second interactions. citeturn5view0turn10view3  

**Accessibility and UX constraints**
- One-handed use: bottom-aligned primary controls, large buttons, minimal navigation.
- “No typing” default: numeric keypad is secondary and optional.
- High-contrast mode and large text for quick glance in motion.
- “Noisy environment” assumption aligns with the transport operating environment of fast, informal services described as demand-responsive and heavily used. citeturn17view4turn11view1  

### Later features and their requirement implications

**Smart Change Algorithm upgrades**
- Configurable objective function:
  - Minimize number of items (bills/coins).
  - Prefer larger bills (faster handoff) unless inventory is low.
  - Prefer “protect small change” strategy (keep 1s/5s for later).
- Configurable rounding tolerance (explicit opt-in):
  - Max rounding amount (e.g., 0, 1, 2 EGP).
  - Only allow rounding when change is infeasible, not as default behavior.
  - Must show passenger-facing disclosure and track separately as “rounding delta,” reflecting compliance risk sensitivity post fare adjustments. citeturn17view2turn17view0  

**Voice Mode (Arabic STT)**
- Supported commands: “اتنين من مية”, “واحد من خمسين”, “ثلاثة من متين”.
- Must function with background noise; Whisper is explicitly designed for robustness to accents/noise in multilingual ASR training claims, but dialect performance should be validated in Egyptian Arabic conditions. citeturn12search11turn12search26  
- Must support Egyptian Arabic locale where possible (ar‑EG). citeturn14view0turn12search1  

**Analytics**
- On-device daily summaries first; cloud analytics only if consented.
- Discrepancy tracking: difference between “expected cash” vs “actual pocket changes” over day, useful for self-audit and dispute resolution.

**Privacy/security**
- If any digital-payment hooks are added later (e.g., a “send change later” via transfer), the app should integrate with established Egyptian rails and explicitly follow the principle that financial transactions occur through banks; InstaPay’s terms describe that transactions are executed by the issuing banks and that InstaPay does not access sensitive balance/records. citeturn19search23turn10view5  

## Technical architecture and algorithms

An offline-first cash tool can be built with minimal infrastructure. The architecture should reflect the informality and variability highlighted in transport research: many routes, high frequency, and uneven data availability. citeturn5view3turn5view0turn10view2

### Architecture options

| Option | Components | Pros | Cons | Best fit |
|---|---|---|---|---|
| Local-only MVP | Flutter UI + local DB (Hive/SQLite) | Fast, offline, low cost, simplest privacy story | No cross-device sync; limited product analytics | Solo collector/driver use; fastest launch |
| Local + optional telemetry | Local-only + anonymized event counters | Basic product insights without user accounts | Must handle consent, privacy messaging | Early-stage validation |
| Cloud sync (fleet) | Local DB + backend (Firebase/custom) | Multi-device, fleet dashboards, anti-loss | Highest complexity, regulatory perception risk | Transport companies / formal operators |
| “Passenger verification” web share | Local compute + QR share of computed results | Helps disputes and transparency | Must prevent spoofing; UX complexity | High-dispute routes / compliance-sensitive settings |

Transport policy context suggests microbuses dominate daily trips and operate under periodic enforcement; this increases the value of transparent on-device computation and reduces the need for risky financial integrations in v1. citeturn10view3turn17view0turn17view2

### Data storage choice: Hive vs SQLite

| Dimension | Hive | SQLite |
|---|---|---|
| Speed for simple KV counters | Excellent | Good |
| Schema evolution | Easy for small models | Requires migrations |
| Querying (reports over many transactions) | Limited | Strong (SQL aggregations) |
| Risk profile | Low | Low |
| Recommendation | MVP Pocket Mode + daily totals | Later: if needing detailed audits, SQLite |

### Third-party Arabic speech-to-text options

| Provider | Arabic (Egypt) locale | Strengths | Weaknesses | Citation |
|---|---|---|---|---|
| entity["company","Google Cloud","cloud platform"] Speech-to-Text | ar‑EG supported | Wide language support; strong ecosystem | Network dependency; cost; privacy review needed | citeturn14view0turn13view0 |
| entity["company","Microsoft Azure","cloud services"] Speech | ar‑EG supported | Explicit locale list; enterprise controls | Network dependency; cost; tuning required | citeturn12search1 |
| entity["company","Amazon Web Services","cloud services"] Transcribe | Arabic supported (Gulf ar‑AE; MSA ar‑SA) | Mature streaming/batch; vocab features | No explicit Egyptian locale; dialect gap risk | citeturn15view0 |
| entity["company","OpenAI","ai company"] Whisper (local or API) | Arabic supported; dialect varies | Robustness to noise/accents claimed; can run on-device | Device performance cost; dialect accuracy must be field-tested | citeturn12search11turn13view1turn12search26 |

Given microbus noise and dialect specificity, Voice Mode should be treated as **later-stage** and validated through in-vehicle testing before relying on it for core workflows. citeturn12search26turn11view1

### Sample change-calculation algorithm

The problem is a **bounded change-making** task when Pocket Mode is enabled: find a set of denominations whose sum equals required change, using at most the available count per denomination, while optimizing for minimal number of items and/or preferred denominations. This is the technical core that addresses “lack of change” dynamics described in user narratives. citeturn2search17turn19search14

```text
Inputs:
  fare_per_rider: int (EGP)
  riders: int
  paid: int
  denom = [200, 100, 50, 20, 10, 5, 1]
  inventory[denom]: available counts (optional; if omitted, treat as infinite)
  rounding_max: int (default 0; opt-in)

Compute:
  total = fare_per_rider * riders
  change_due = paid - total

If change_due < 0:
  Output: "Still owed = -change_due" (no change plan)

Else:
  Try to find exact change plan:
    1) If inventory is infinite:
         Use greedy (because denom is canonical) to minimize count.
    2) If inventory is bounded:
         Use dynamic programming:
           dp[x] = best plan to make x (min items; tie-break prefer larger denoms)
         Iterate denoms with bounded counts.

  If exact plan exists:
     Output plan and (if Pocket Mode) update inventory.
  Else:
     If rounding_max > 0:
         For r in 1..rounding_max:
           Try plan for (change_due - r)  // reduces change given
           If feasible:
              Output plan + "rounding_delta = r" (must be disclosed)
              break
     If still no plan:
         Output: "Cannot make change" + options:
              - partial change + IOU amount
              - request smaller bill
              - hold change until later stop
```

#### Worked examples (using typical microbus phrasing structure)

Example A: “اتنين من 100”, fare=15  
- riders=2 → total=30; paid=100 → change_due=70  
- If inventory allows: suggest **50 + 20** (2 items).  
This mirrors the practical need to respond instantly to a “two from 100” payment. citeturn19search14turn2search17

Example B: change exists mathematically but not in pocket  
- change_due=70  
- inventory: {50×0, 20×1, 10×0, 5×0, 1×0}  
- No exact plan possible → app must say “cannot make 70” and propose “give 20 now + IOU 50” or request smaller note.  
This targets the “مشكلة الفكة” and confusion described in narrative accounts. citeturn2search17turn17view0

Example C: rounding policy (explicit opt-in)  
- change_due=7; inventory has no 1s/5s, only 10s  
- rounding_max=2 → try change_due-1=6 (still infeasible), change_due-2=5 (feasible if 5 exists; if not, still fail)  
- If feasible, app records “rounding_delta=2” (must be shown clearly and tracked).  
This must be ethically framed as transparent rounding under constraint, not default short-changing, especially under active fare compliance regimes. citeturn17view2turn17view0

## Testing, go-to-market, risks, and KPIs

### Testing plan

**Field testing requirements** should reflect real operating conditions described in transport research: high frequency, congestion variation, and informal route dominance. citeturn11view1turn10view3turn5view0

**Usability protocol (moving vehicle)**
- Recruit: 10–15 collectors/drivers across 3 route types (dense central Cairo, peri-urban connectors, and one lower-density/rural-like corridor where applicable). Route diversity matters because informal routes vary in length, demand, and context. citeturn11view1turn10view3  
- Tasks: complete 20 scripted transactions per participant:
  - single rider small bills
  - “2 from 100” and “3 from 200”
  - “no change” constraints with Pocket Mode
  - (later) Voice Mode commands with noise
- Measures:
  - time-to-result (goal: <1s compute; <3s interaction end-to-end)
  - error rate (wrong change suggested)
  - recovery success (how quickly user resolves “cannot make change” cases)
  - subjective workload (NASA-TLX short form)
- Safety: no testing that distracts the driver; collector-only testing while vehicle is moving; driver testing while stopped at terminal. This constraint is essential given the transport environment.

**Bench tests**
- Performance regression: 10,000 synthetic transactions; ensure no memory leaks.
- Battery profiling: continuous use simulation (screen on, taps every 10s for 1 hour).

### Suggested interview and survey questions

Collector/driver interviews should probe cash inventory patterns and dispute frequency, consistent with documented “change reminder” norms and the operational reality that data about patronage can be fragmented. citeturn5view0turn19search14

Sample questions (collector/driver):
- “What are the 5 most common fares on your route and the most common bills passengers pay with after each fare change?” citeturn17view0turn17view2  
- “How often per trip do you face ‘no change’ situations, and what do you do (delay, borrow, partial change, ask passenger to swap)?” citeturn2search17turn19search14  
- “Do you prefer to keep small change (1/5) or keep larger bills? Why?” citeturn2search17  
- “How many seconds would you tolerate looking at a phone per transaction?”  
- “Would you use voice input if accuracy is imperfect in noise?”

Passenger surveys:
- “How often do you argue about change or fare correctness per week?” citeturn17view0  
- “Would you use a ‘fare check’ screen during disputes?” citeturn17view0  
- “What is the most common phrase you use when paying (e.g., اتنين من…)?”

### Go-to-market and monetization

**Viral mechanics**
- Microbus culture uses shared phrasing and visible behaviors (e.g., passing money forward, shouting for change); a tool that visibly speeds up change could spread via observation and word-of-mouth at major موقف hubs. citeturn19search14turn11view1  
- A “Passenger verification” screen supports transparency during periods of fare enforcement campaigns and posted tariffs. citeturn17view0turn17view2  

**Partnership paths**
- Start with semi-formal operators first (private minibus companies, or collective transport companies where standardized fares exist), then expand to informal microbus collectors. Official documentation and reporting show fare tables and route structures for collective transport, providing clearer initial constraints for pilots. citeturn8view1turn10view4turn17view0  

**Monetization options**
- Freemium:
  - Free: calculator + basic Smart Change
  - Premium: Pocket Mode history, export, presets library, (later) Voice Mode
- Ads: only in non-transaction screens to avoid distraction risk.
- B2B licensing: for fleets/companies wanting standardized daily reconciliation.

### Risks, regulatory/ethical concerns, and mitigations

**Risk: enabling theft / intentional short-changing**  
Because fare compliance is actively monitored after fare increases, and governorate messaging ties violations to legal measures, any “keep change” feature can be perceived as enabling exploitation. citeturn17view0turn17view2turn17view1  
Mitigation:
- Default “Fair Mode”: exact change required; rounding disabled by default.
- If rounding enabled: explicit on-screen disclosure, per-transaction confirmation, and a separate ledger line item (“rounding delta”) visible in Passenger Mode.
- Add “Request smaller bill” suggestion before any rounding.

**Risk: liability from distracted use**  
Mitigation:
- Explicit product guidance: “Collector use while moving; driver use only when stopped.”
- UX: large tap targets, minimal screens, no scrolling required.

**Risk: privacy concerns (tracking earnings)**  
Mitigation:
- Store by default locally; no account required.
- Optional PIN/biometric gate to open ledger.
- If any future integration with payments rails is considered, align with existing terms and constraints; for example, InstaPay terms emphasize that transactions occur through the customer’s bank and that InstaPay does not access sensitive balance/financial record data. citeturn19search23  

**Risk: rapid fare changes break presets**  
Mitigation:
- Fare presets are parameterized (fare value stored separately); updating fare auto-updates calculations.
- “Fare update” quick banner on the main screen during configured date ranges (user toggles).

### KPIs to measure success

Metrics should reflect both micro-interaction improvements and trust outcomes in a system with high daily volume. citeturn10view3turn11view1

**Adoption**
- Weekly active collectors (WAC), daily active collectors (DAC)
- Retention at 7/30 days

**Operational efficiency**
- Median time from payment input → change plan display (target: <1s compute, <3s interaction)  
- % of transactions using Pocket Mode  
- % of “cannot make change” events resolved via suggested fallback

**Accuracy / trust**
- User-reported dispute reduction (pre/post survey)
- Rate of “manual override” after suggestion
- Passenger Mode usage during disputes (proxy for transparency value) citeturn17view0  

**Economics**
- Conversion rate to premium
- ARPDAU (if ads enabled) with strict constraints to avoid in-transaction ads

**Ethical safeguards**
- % of transactions where rounding is used (should be low; monitored)
- User feedback reports referencing unfairness or exploitation (qualitative leading indicator)