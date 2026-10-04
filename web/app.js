// ==========================================================================
// mailto: Landing Page Interactive Logic
// ==========================================================================

document.addEventListener('DOMContentLoaded', () => {
  initClipboardButtons();
  initSimulator();
  initInstallTabs();
});

// ==========================================================================
// 1. Copy to Clipboard Handlers
// ==========================================================================
function initClipboardButtons() {
  const heroCopyBtn = document.getElementById('hero-copy-btn');
  const brewHeroCmd = document.getElementById('brew-hero-cmd');
  const copyToast = document.getElementById('copy-toast');

  if (heroCopyBtn && brewHeroCmd && copyToast) {
    heroCopyBtn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(brewHeroCmd.innerText.trim());
        heroCopyBtn.querySelector('.copy-text').textContent = 'Copied!';
        copyToast.classList.add('show');
        
        setTimeout(() => {
          heroCopyBtn.querySelector('.copy-text').textContent = 'Copy';
          copyToast.classList.remove('show');
        }, 2200);
      } catch (err) {
        console.error('Failed to copy command:', err);
      }
    });
  }

  // Generic tab copy buttons
  document.querySelectorAll('.tab-copy-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const textToCopy = btn.getAttribute('data-copy');
      if (!textToCopy) return;

      try {
        await navigator.clipboard.writeText(textToCopy);
        const originalText = btn.textContent;
        btn.textContent = 'Copied!';
        btn.style.color = '#10b981';

        setTimeout(() => {
          btn.textContent = originalText;
          btn.style.color = '';
        }, 2000);
      } catch (err) {
        console.error('Failed to copy:', err);
      }
    });
  });
}

// ==========================================================================
// 2. Interactive macOS Live Dispatch Simulator
// ==========================================================================
function initSimulator() {
  const simButtons = document.querySelectorAll('.sim-btn');
  const fnToggle = document.getElementById('fn-toggle');

  const displayUrl = document.getElementById('display-url');
  const ruleExplanation = document.getElementById('rule-explanation');
  const dispatchExplanation = document.getElementById('dispatch-explanation');
  const destIcon = document.getElementById('dest-icon');
  const destTarget = document.getElementById('dest-target');
  const destAction = document.getElementById('dest-action');
  const destUrlPreview = document.getElementById('dest-url-preview');
  const pipelineStatus = document.getElementById('pipeline-status');

  const scenarios = {
    'dev@acme-corp.com': {
      title: 'Work Domain Rule',
      matchedRule: 'Matched domain rule <strong>@acme-corp.com</strong>',
      targetName: 'Outlook 365 (Work Webmail)',
      actionText: 'Opening browser tab with pre-filled composer:',
      url: 'https://outlook.office.com/mail/deeplink/compose?to=dev@acme-corp.com',
      icon: '🏢',
      dispatchText: 'Directing to Outlook 365 (Webmail)'
    },
    'notifications@github.com': {
      title: 'Fastmail Rule',
      matchedRule: 'Matched sender domain <strong>@github.com</strong>',
      targetName: 'Fastmail (Webmail)',
      actionText: 'Opening Fastmail in default browser:',
      url: 'https://app.fastmail.com/mail/compose?to=notifications@github.com',
      icon: '⚡',
      dispatchText: 'Routing to Fastmail Webmail'
    },
    'friend@gmail.com': {
      title: 'Default Fallback',
      matchedRule: 'No specific rule matched → <em>Using Primary Target</em>',
      targetName: 'Gmail (Primary Target)',
      actionText: 'Opening Gmail compose window in browser:',
      url: 'https://mail.google.com/mail/?view=cm&fs=1&to=friend@gmail.com',
      icon: '✉️',
      dispatchText: 'Directing to Primary Target (Gmail)'
    },
    'invoicing@supplier.io': {
      title: 'Copy to Clipboard',
      matchedRule: 'Matched rule <strong>Finance & Invoices</strong>',
      targetName: 'System Clipboard (No window opened!)',
      actionText: 'Silently extracted address into macOS clipboard:',
      url: 'Copied: invoicing@supplier.io (0 browser tabs spawned)',
      icon: '📋',
      dispatchText: 'Copied cleanly to system pasteboard'
    }
  };

  let activeEmail = 'dev@acme-corp.com';

  function renderSimulation() {
    const isFnActive = fnToggle ? fnToggle.checked : false;
    const randomMs = Math.floor(Math.random() * 5) + 10; // 10-14ms

    displayUrl.textContent = `mailto:${activeEmail}`;

    if (isFnActive) {
      // Fn modifier overrides everything
      ruleExplanation.innerHTML = '⌨️ <strong>Fn Key Active:</strong> Bypassing all custom rules!';
      dispatchExplanation.textContent = 'Redirected to Alternative Target (Apple Mail)';
      destIcon.textContent = '🍎';
      destTarget.textContent = 'Apple Mail (Alternative Target)';
      destAction.textContent = 'Invoked native desktop compose sheet:';
      destUrlPreview.textContent = `Apple Mail launched with recipient: ${activeEmail}`;
      pipelineStatus.textContent = `Fn Override • Dispatched in ${randomMs}ms`;
      pipelineStatus.style.color = '#f59e0b';
      pipelineStatus.style.borderColor = 'rgba(245, 158, 11, 0.35)';
      pipelineStatus.style.background = 'rgba(245, 158, 11, 0.1)';
    } else {
      const data = scenarios[activeEmail] || scenarios['dev@acme-corp.com'];
      ruleExplanation.innerHTML = data.matchedRule;
      dispatchExplanation.textContent = data.dispatchText;
      destIcon.textContent = data.icon;
      destTarget.textContent = data.targetName;
      destAction.textContent = data.actionText;
      destUrlPreview.textContent = data.url;
      pipelineStatus.textContent = `Dispatched in ${randomMs}ms`;
      pipelineStatus.style.color = '#10b981';
      pipelineStatus.style.borderColor = 'rgba(16, 185, 129, 0.25)';
      pipelineStatus.style.background = 'rgba(16, 185, 129, 0.1)';
    }

    // Trigger subtle card flash animation
    const destCard = document.getElementById('destination-card');
    if (destCard) {
      destCard.style.transform = 'scale(0.985)';
      setTimeout(() => {
        destCard.style.transform = 'scale(1)';
      }, 120);
    }
  }

  simButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      simButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeEmail = btn.getAttribute('data-email');
      renderSimulation();
    });
  });

  if (fnToggle) {
    fnToggle.addEventListener('change', () => {
      renderSimulation();
    });
  }

  // Initial render
  renderSimulation();
}

// ==========================================================================
// 3. Installation Tabs Switcher
// ==========================================================================
function initInstallTabs() {
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTabId = btn.getAttribute('data-tab');

      tabButtons.forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
      });

      tabPanes.forEach(pane => {
        pane.classList.remove('active');
      });

      btn.classList.add('active');
      btn.setAttribute('aria-selected', 'true');

      const activePane = document.getElementById(targetTabId);
      if (activePane) {
        activePane.classList.add('active');
      }
    });
  });
}
