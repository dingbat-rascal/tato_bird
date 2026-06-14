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
Content Disclaimer & Limitation of Liability This application utilizes language learning data sourced from Tatoeba. Content is generated entirely by third-party users. We do not actively monitor, [...]

# A Tatoeba fork of Birdee Brains primarily for language learning

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
        { "<C-g>", function () require("birdee_brains").show_menu() end, desc = "Start Birdee Brains" },
    },
    choice_keys = { "j", "k", "l", ";" },  -- multiple choice selection keys
}
```

### Quick Start

1. Install the plugin and extact the tatoeba.db file from the tatoeba.tar.gz in:
  - Linux / macOS: ~/.local/share/nvim/lazy/tato_bird/
  - Windows: ~/AppData/Local/nvim-data/lazy/tato_bird/
2. Press `<C-g>` to launch
3. Select a lesson from the menu
4. In **multiple choice** mode: Press `jkl;` to select answers

## History

The original birdee_brains was useful for personalized learning. This Tatoeba fork leverages the extensive [Tatoeba community database](https://tatoeba.org) of multilingual sentences.

**Fun Fact:** [Tatoeba](https://en.wikipedia.org/wiki/Tatoeba) contributors are known as "Tatoebans"

## Roadmap

    - [ ] **Analytics Suit:** A grading/progression system to display highscores and charts of your
      record allowing you to easily identify your strengths, and weak points.
    - [ ] **Streak System:** Reminder to check in. Display steak to insitivise
      daily practice.
    - [ ] **Universal Phonetic Alphabet:** Incorporate a way to display the International
      Phonetic Alphabet.

<img width="500" height="375" alt="ralphlearning" src="https://github.com/user-attachments/assets/272a4a63-e7d7-4713-bce3-6add3333caed" />
