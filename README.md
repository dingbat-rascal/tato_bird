<p align="center">
  <pre>
  _________
< Trang Ho! > 
 -----\ ---           _?_
        _?_          {:,:}/>
       (:,:)         /)__)'
       {`"'}          " "      ▄▄▄▄· ▪  ▄▄▄  ·▄▄▄▄  
   ▄▄▄▄▀ ██     ▄▄▄▄▀ ████▄    ▐█ ▀█▪██ ▀▄ █·██▪ ██ 
▀▀▀ █    █ █ ▀▀▀ █    █   █    ▐█▀▀█▄▐█·▐▀▀▄ ▐█· ▐█▌
    █    █▄▄█    █    █   █    ██▄▪▐█▐█▌▐█•█▌██. ██ 
   █     █  █   █     ▀████    ·▀▀▀▀ ▀▀▀.▀  ▀▀▀▀▀▀• 
  ▀         █  ▀            
           █                
          ▀                 
  </pre>
</p>

# Attention
Content Disclaimer & Limitation of Liability This application utilizes language learning data sourced from Tatoeba, a community-driven, crowd-sourced database of sentences and translations.No Pre-Screening: Content is generated entirely by third-party users. We do not actively monitor, verify, or pre-screen these submissions. Accuracy and Appropriateness: We do not guarantee the accuracy, grammatical correctness, safety, or appropriateness of any sentence. You may encounter content that is inaccurate, offensive, or mature. Assumption of Risk: By using this app, you acknowledge that you expose yourself to user-generated data at your own risk. The app developers are not liable for any damages or offense caused by this content. Report Content: If you find a sentence that is highly inappropriate, offensive, or incorrect, please use our reporting tool to flag it for review.

# Tatoeba
A fork of [Birdee Brains](https://github.com/dingbat-rascal/birdee_brains) primarily for language learning

A quick, fun, interactive way to practice multiple choice directly inside your
editor with vim motions. Features reinforcement learning for mistakes.
Made for language learning and foreign keyboard typing practice in your downtime.
Fully customizable for any subject in true vim spirit.

Uses the [Tatoeba](https://tatoeba.org) sentence database to compile your desired lessons.

### Preview

## 📦 Installation

```lua
return {
    "dingbat-rascal/tato_bird",
    keys = {
        { "<C-g>", function () require("tato_bird").show_menu() end, desc = "Start Tato Bird" },
    },
opts = {
    choice_keys = { "j", "k", "l", ";" },  -- multiple choice selection keys
  }
}
```

### Quick Start

1. Install the plugin then extact the [tatoeba.tar.gz](https://github.com/dingbat-rascal/tato_bird/releases/) inside this repos dir:
  - Linux / macOS: ~/.local/share/nvim/${package_manager}/tato_bird/
  - Windows: ~/AppData/Local/nvim-data/%PACKAGE_MANAGER%/tato_bird/
2. now that tatoeba.db is in place, launch nvim and Press `<C-g>` to reveal ui
3. Select a lesson from the menu
4. In **multiple choice** mode: Press `jkl;` to select answers

## History

The original [Birdee Brains](https://github.com/dingbat-rascal/birdee_brains) was useful for personalized learning. This Tatoeba fork leverages the extensive [Tatoeba community database](https://tatoeba.org) of multilingual sentences.

**Fun Fact:** [Tatoeba](https://en.wikipedia.org/wiki/Tatoeba) contributors are known as "Tatoebans"

## Issues
  - The new [tatoeba.db](https://github.com/dingbat-rascal/tato_bird/releases/) is faster then the previous, but still large. Some queries only return 1 sentence.
  - While community driven is good, its not always. Users can subbmit mature content, other users use online gambling sites for user names.

# Attention
Content Disclaimer & Limitation of Liability This application utilizes language learning data sourced from Tatoeba, a community-driven, crowd-sourced database of sentences and translations.No Pre-Screening: Content is generated entirely by third-party users. We do not actively monitor, verify, or pre-screen these submissions. Accuracy and Appropriateness: We do not guarantee the accuracy, grammatical correctness, safety, or appropriateness of any sentence. You may encounter content that is inaccurate, offensive, or mature. Assumption of Risk: By using this app, you acknowledge that you expose yourself to user-generated data at your own risk. The app developers are not liable for any damages or offense caused by this content. Report Content: If you find a sentence that is highly inappropriate, offensive, or incorrect, please use our reporting tool to flag it for review.


## Roadmap
    - [ ] **Analytics Suit:** A grading/progression system to display highscores and charts of your
      record allowing you to easily identify your strengths, and weak points.
    - [ ] **Streak System:** Reminder to check in. Display steak to insitivise
      daily practice.
    - [ ] **Universal Phonetic Alphabet:** Incorporate a way to display the International
      Phonetic Alphabet.

<img width="500" height="375" alt="ralphlearning" src="https://github.com/user-attachments/assets/272a4a63-e7d7-4713-bce3-6add3333caed" />
