;;;  -*- lexical-binding: t; -*-

(after! cc
  (add-hook! c-mode
    (setq-default c-basic-offset 8
                  tab-width 8
                  indent-tabs-mode t
                  doom-line-numbers-style 'relative)))

(setq-default doom-line-numbers-style 'relative)

(add-hook! 'before-save-hook #'delete-trailing-whitespace)

(after! python
  (setq python-shell-interpreter "python3"
        flycheck-python-pycompile-executable "python3"))

;; (after! evil
;;   (evil-ex-define-cmd "q" #'kill-this-buffer))

;; Use fuzzy searching for finding files
(after! ivy
  (setq ivy-re-builders-alist
        '((t . ivy--regex-fuzzy))))

;; (load! +ranger)
;;

(add-hook! 'prog-mode #'goto-address-mode)

(require 'multi-term)
(load! +lisp)
(load! +org)
