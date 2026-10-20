;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin
      catppuccin-flavor 'macchiato) ; or 'latte, 'frappe, 'mocha
;; Specify both a dark and light theme, like so and Doom will choose which one
;; to load based on your system light/dark setting:
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (DARK . LIGHT)
;;
;; If you want more pro-active theme switching based on OS light/dark mode, look
;; up the `auto-dark' package.

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)



;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;;; Research and knowledge base

(defvar my/research-root
  (expand-file-name "~/research/"))

(setq org-directory my/research-root
      org-roam-directory
      (expand-file-name "roam/" my/research-root))

;;; Research paper bibliography

(setq citar-bibliography
      (list (expand-file-name
             "references.bib" my/research-root))
      org-cite-global-bibliography citar-bibliography
      citar-library-paths
      (list (expand-file-name
             "library/pdfs/" my/research-root))
      ;; Notes opened from citar go next to the "p" capture template's notes
      citar-org-roam-subdir "papers")

;;; Org-roam: interconnected notes

(after! org-roam
  (setq org-roam-capture-templates
        '(("p" "Research paper" plain
           "* Problem\n%?\n\n\
* Main contribution\n\n\
* Mechanism\n\n\
* Evaluation\n\n\
* Limitations\n\n\
* Connections to other work\n\n\
* Open questions\n"
           :target
           (file+head
            "papers/%<%Y%m%d%H%M%S>-${slug}.org"
            "#+title: ${title}\n")
           :unnarrowed t)

          ("c" "Concept" plain
           "* Definition\n%?\n\n\
* Mechanism\n\n\
* Examples\n\n\
* Related papers\n"
           :target
           (file+head
            "concepts/%<%Y%m%d%H%M%S>-${slug}.org"
            "#+title: ${title}\n")
           :unnarrowed t)

          ("r" "Research project" plain
           "* Research question\n%?\n\n\
* Hypothesis\n\n\
* Related work\n\n\
* Experiments\n\n\
* Next actions\n"
           :target
           (file+head
            "projects/%<%Y%m%d%H%M%S>-${slug}.org"
            "#+title: ${title}\n")
           :unnarrowed t)))

  ;; Journal: daily Org-roam notes
  (setq org-roam-dailies-directory "daily/"
        org-roam-dailies-capture-templates
        '(("j" "Journal" entry
           "* Journal %<%H:%M>\n%?"
           :target
           (file+head
            "%<%Y-%m-%d>.org"
            "#+title: %<%Y-%m-%d>\n"))

          ("r" "Research log" entry
           "* Research log %<%H:%M>\n\
- Papers read:\n\
- Findings:\n\
- Questions:\n\
- Next actions:\n%?"
           :target
           (file+head
            "%<%Y-%m-%d>.org"
            "#+title: %<%Y-%m-%d>\n"))))

  (org-roam-db-autosync-mode 1))

;;; Predictable shortcuts in Doom and terminal Emacs

(global-set-key (kbd "C-c r f")
                #'org-roam-node-find)

(global-set-key (kbd "C-c r i")
                #'org-roam-node-insert)

(global-set-key (kbd "C-c r l")
                #'org-roam-buffer-toggle)

(global-set-key (kbd "C-c r j")
                #'org-roam-dailies-capture-today)

(global-set-key (kbd "C-c r b")
                #'citar-open)

(global-set-key (kbd "C-c r c")
                #'citar-insert-citation)

;;; General org

(after! org
  (setq org-startup-with-inline-images t
        org-capture-templates
        `(("t" "Todo without link" entry
           (file+headline ,(expand-file-name "todo.org" my/research-root) "Tasks")
           "* TODO %?\n")
          ("T" "Todo with link" entry
           (file+headline ,(expand-file-name "todo.org" my/research-root) "Tasks")
           "* TODO %?\n  %U\n  %a")
          ("d" "Daily Diary Entry" entry
           (file+olp+datetree ,(expand-file-name "diary.org" my/research-root))
           "* %U\n%?\n"))))

(custom-set-faces!
  '(org-table :foreground "#ffcc66" :weight bold :height 1.1))

;; (DIR . 0) registers DIR itself as a project rather than its subfolders
(setq projectile-project-search-path '("~/codes" ("~/research" . 0)))

;;; NvChad-style keys

(defun my/neotree-toggle ()
  "Toggle neotree, opening it at the project root."
  (interactive)
  (if (neo-global--window-exists-p)
      (neotree-hide)
    (+neotree/open)))

(map! :n "C-n" #'my/neotree-toggle
      :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right
      (:after neotree
       :map neotree-mode-map
       :n "C-n" #'my/neotree-toggle
       :n "C-h" #'evil-window-left
       :n "C-j" #'evil-window-down
       :n "C-k" #'evil-window-up
       :n "C-l" #'evil-window-right)
      ;; org uses C-j/C-k for headings; those stay on ]h / [h
      (:after evil-org
       :map evil-org-mode-map
       :n "C-j" #'evil-window-down
       :n "C-k" #'evil-window-up))
