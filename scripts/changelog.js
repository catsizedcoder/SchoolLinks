(function() {
    async function loadChangelog() {
        try {
            const response = await fetch('changelog.json');
            if (!response.ok) throw new Error('Failed to load changelog');
            return await response.json();
        } catch (error) {
            console.error('Error loading changelog:', error);
            return null;
        }
    }

    function createCLDialog(changelogdat) {
        const overlay = document.createElement('div');
        overlay.className = 'changelog-overlay';
        overlay.id = 'changelog-overlay';

        const sectionsHTML = changelogdat.sections.map(section => `
            <div class="changelog-section">
                <h3>${section.title}</h3>
                ${section.items.map(item => `
                    <div class="changelog-item">${item}</div>
                `).join('')}
            </div>
        `).join('');

        overlay.innerHTML = `
            <div class="changelog-dialog">
                <div class="changelog-header">
                    <h2>${changelogdat.title || 'What\'s New with SchoolLinks?'}</h2>
                    <div class="changelog-version">Version ${changelogdat.version}</div>
                </div>
                <div class="changelog-content">
                    ${sectionsHTML}
                </div>
                <div class="changelog-footer">
                    <button class="changelog-close-btn" id="changelog-close">Close</button>
                </div>
            </div>
        `;

        document.body.appendChild(overlay);

        document.getElementById('changelog-close').addEventListener('click', () => {
            closeDialog();
            localStorage.setItem('savedCLVersion', changelogdat.version);
        });

        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                closeDialog();
                localStorage.setItem('savedCLVersion', changelogdat.version);
            }
        });
    }

    function showDialog() {
        const overlay = document.getElementById('changelog-overlay');
        if (overlay) {
            overlay.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }

    function closeDialog() {
        const overlay = document.getElementById('changelog-overlay');
        if (overlay) {
            overlay.classList.remove('active');
            document.body.style.overflow = '';
        }
    }

    function createTriggerButton(targetElement) {
        const button = document.createElement('button');
        button.className = 'changelog-trigger-btn';
        button.textContent = 'View Changelog';
        button.addEventListener('click', showDialog);
        
        if (targetElement) {
            targetElement.appendChild(button);
        }
        
        return button;
    }

    async function initChangelog(options = {}) {
        const {
            autoShow = true,
        } = options;

        const changelogdat = await loadChangelog();
        
        if (!changelogdat) {
            console.error('Failed to initialize changelog: No data loaded');
            return;
        }

        createCLDialog(changelogdat);

        const savedVersion = localStorage.getItem('savedCLVersion');
        
        if (autoShow && (!savedVersion || savedVersion !== changelogdat.version)) {
            showDialog();
        }

        return {
            show: showDialog,
            close: closeDialog,
        };
    }

    window.changelog = {
        init: initChangelog,
        show: showDialog,
        close: closeDialog
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            initChangelog({ autoShow: true });
        });
    } else {
        initChangelog({ autoShow: true });
    }
})();