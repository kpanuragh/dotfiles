;;; init.el -*- lexical-binding: t; -*-

;; Doom Emacs config for terminal-only use (emacs -nw on Gentoo).
;; Tuned for org-mode workflows and general coding (LSP via eglot, magit).
;; Run `doom sync` after editing this file.

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets
       (whitespace +guess +trim)

       :emacs
       dired
       electric
       ibuffer
       tramp
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       direnv
       editorconfig
       (eval +overlay)
       lookup
       (lsp +eglot)
       magit
       tree-sitter

       :os
       tty

       :lang
       data
       emacs-lisp
       json
       markdown
       org
       (python +lsp)
       sh
       web
       yaml

       :config
       (default +bindings +smartparens))
