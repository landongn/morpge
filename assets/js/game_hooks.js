// Game Interface JavaScript Hooks

const GameHooks = {
  // Hook for status bar width calculations
  StatusBar: {
    mounted() {
      this.updateStatusBar();
      this.handleEvent("status_update", () => this.updateStatusBar());
    },

    updateStatusBar() {
      const current = parseInt(this.el.dataset.current);
      const max = parseInt(this.el.dataset.max);
      
      if (current && max && max > 0) {
        const percentage = (current / max) * 100;
        this.el.style.width = `${percentage}%`;
      }
    }
  },

  // Hook for chat message auto-scrolling
  ChatMessages: {
    mounted() {
      this.scrollToBottom();
      this.handleEvent("new_message", () => this.scrollToBottom());
    },

    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight;
    }
  },

  // Hook for command input history
  CommandInput: {
    mounted() {
      this.commandHistory = [];
      this.historyIndex = -1;
      
      this.el.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowUp') {
          e.preventDefault();
          this.navigateHistory('up');
        } else if (e.key === 'ArrowDown') {
          e.preventDefault();
          this.navigateHistory('down');
        } else if (e.key === 'Enter' && this.el.value.trim()) {
          this.addToHistory(this.el.value);
        }
      });
    },

    addToHistory(command) {
      this.commandHistory.unshift(command);
      if (this.commandHistory.length > 50) {
        this.commandHistory.pop();
      }
      this.historyIndex = -1;
    },

    navigateHistory(direction) {
      if (this.commandHistory.length === 0) return;

      if (direction === 'up') {
        if (this.historyIndex < this.commandHistory.length - 1) {
          this.historyIndex++;
        }
      } else {
        if (this.historyIndex > -1) {
          this.historyIndex--;
        }
      }

      if (this.historyIndex >= 0) {
        this.el.value = this.commandHistory[this.historyIndex];
      } else {
        this.el.value = '';
      }
    }
  },

  // Hook for entity interaction
  EntityItem: {
    mounted() {
      this.el.addEventListener('click', () => {
        const entityName = this.el.querySelector('.entity-name').textContent;
        this.pushEvent('examine_entity', { entity: entityName });
      });
    }
  },

  // Hook for channel switching
  ChannelBox: {
    mounted() {
      this.el.addEventListener('click', () => {
        const channel = this.el.dataset.channel;
        this.pushEvent('switch_channel', { channel: channel });
      });
    }
  }
};

// Register all hooks
Object.entries(GameHooks).forEach(([name, hook]) => {
  window.Hooks = window.Hooks || {};
  window.Hooks[name] = hook;
});

// Auto-scroll chat messages when new content is added
document.addEventListener('DOMContentLoaded', () => {
  const chatMessages = document.querySelectorAll('.chat-messages');
  
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        mutation.target.scrollTop = mutation.target.scrollHeight;
      }
    });
  });

  chatMessages.forEach((chat) => {
    observer.observe(chat, { childList: true });
  });
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  // Ctrl/Cmd + 1-3 to switch channels
  if ((e.ctrlKey || e.metaKey) && e.key >= '1' && e.key <= '3') {
    e.preventDefault();
    const channels = ['world', 'local', 'system'];
    const channelIndex = parseInt(e.key) - 1;
    const channel = channels[channelIndex];
    
    // Dispatch custom event for channel switching
    const event = new CustomEvent('switch_channel', { 
      detail: { channel: channel } 
    });
    document.dispatchEvent(event);
  }
  
  // Escape to clear command input
  if (e.key === 'Escape') {
    const commandInput = document.querySelector('.command-input');
    if (commandInput) {
      commandInput.value = '';
      commandInput.focus();
    }
  }
});

// Utility function to format timestamps
function formatTimestamp(timestamp) {
  const date = new Date(timestamp);
  return date.toLocaleTimeString('en-US', { 
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
}

// Export for use in other modules
window.GameUtils = {
  formatTimestamp
};
