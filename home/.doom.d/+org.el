;;;  -*- lexical-binding: t; -*-

(setq +todo-file "~/org/todo.org")
(setq +notes-file "~/org/notes.org")

(after! org
  (map! :map evil-org-mode-map
        :localleader
        :desc "type" :nve "o" #'org-todo
        :desc "schedule" :nve "s" #'org-schedule
        :desc "due" :nve "d" #'org-deadline
        :desc "move" :nve "m" #'org-refile
        :desc "tag" :nve "t" #'org-set-tags-command
        :desc "filter" :nve "f" #'org-match-sparse-tree)
  (setq org-agenda-span 10
        org-agenda-start-on-weekday nil
        org-agenda-start-day "-3d")
  (setq-default
   org-todo-keywords
   '((sequence "[ ](t)" "[-](p)" "[?](m)" "|" "[X](d)" "[#](g)")
     (sequence "TODO(T)" "|" "DONE(D)")
     (sequence "NEXT(n)" "ACTIVE(a)" "WAITING(w)" "LATER(l)" "|" "CANCELLED(c)"))))

(defun +open-todo-file ()
  (interactive)
  "Opens the todo file"
  (find-file +todo-file))

(defun +open-notes-file ()
  (interactive)
  "Opens the notes file"
  (find-file +notes-file))

(map!
 (:leader
   :desc "Open todo file" :nvm "O" #'+open-todo-file
   :desc "Open notes file" :nvm "N" #'+open-notes-file))

(map! :leader
      (:prefix "o"
        :nvm "a" (lambda! (org-agenda nil "a"))))

(setq org-capture-templates
      '(("t" "tasks" entry
         (file+headline +org-default-todo-file "new")
         "* [ ] %?\n%i" :prepend t :kill-buffer t)))

