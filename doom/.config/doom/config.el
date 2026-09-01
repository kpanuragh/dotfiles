;;; config.el -*- lexical-binding: t; -*-

;; Personal info (used by GPG, magit, etc.)
(setq user-full-name "anuragh"
      user-mail-address "kpanuragh@gmail.com")

;; Terminal-friendly UI
(setq doom-theme 'doom-one)
(setq display-line-numbers-type 'relative)

;; Make modeline terminal-friendly (no fancy icons in -nw mode)
(after! doom-modeline
  (setq doom-modeline-icon (display-graphic-p)))

;; Org-mode -------------------------------------------------------------------
(setq org-directory "~/org/")

(after! org
  (setq org-agenda-files (list org-directory)
        org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-log-done 'time
        org-log-into-drawer t
        org-startup-indented t
        org-startup-folded 'content
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")))

  ;; Quick capture templates
  (setq org-capture-templates
        '(("t" "Todo" entry (file+headline "inbox.org" "Tasks")
           "* TODO %?\n  %U\n  %a")
          ("n" "Note" entry (file+headline "inbox.org" "Notes")
           "* %?\n  %U")
          ("j" "Journal" entry (file+datetree "journal.org")
           "* %?\n  %U"))))

;; Coding ---------------------------------------------------------------------
;; LSP via eglot is enabled in init.el. Per-language servers auto-install/use
;; system binaries (e.g. pyright, gopls). Install them separately as needed.

;; Better whitespace defaults
(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

;; Magit polish
(after! magit
  (setq magit-diff-refine-hunk 'all))

;; Auto-save on focus change keeps work safe across long sessions
(use-package! super-save
  :defer 1
  :config
  (super-save-mode +1)
  (setq super-save-auto-save-when-idle t))

;; ---------------------------------------------------------------------------
;; agent-shell — talk to coding agents over ACP (Agent Client Protocol).
;;
;; Auth is :login, NOT an API key: the claude-agent-acp adapter reuses the
;; credentials the Claude Code CLI already holds, so this bills against the
;; existing subscription rather than per-token API usage. Requires:
;;   npm install -g @agentclientprotocol/claude-agent-acp
;;
;; Start with: M-x agent-shell-anthropic-start-claude-code
;; ---------------------------------------------------------------------------
(use-package! agent-shell
  :commands (agent-shell-anthropic-start-claude-code
             agent-shell)
  :config
  (setq agent-shell-anthropic-authentication
        (agent-shell-anthropic-make-authentication :login t)))

;; SPC o a  -> Claude (subscription auth, via claude-agent-acp)
;; SPC o A  -> pick any ACP backend agent-shell knows about
(map! :leader
      (:prefix ("o" . "open")
       :desc "Claude agent shell" "a" #'agent-shell-anthropic-start-claude-code
       :desc "Agent shell (pick)" "A" #'agent-shell))
