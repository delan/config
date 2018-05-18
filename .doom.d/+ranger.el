;;;  -*- lexical-binding: t; -*-

(def-package! ranger
  :commands (ranger deer ranger-override-dired-fn)
  :config
  (setq-default ranger-preview-file nil)) ;; The file preview is buggy for me so I disable it.

(map!
 (:leader
   (:prefix "a"
     :desc "Ranger" :n "r" #'ranger
     :desc "Deer" :n "d" #'deer)))

(add-hook! dired-mode #'ranger-override-dired-fn) ;; Override dired-mode so it uses deer
