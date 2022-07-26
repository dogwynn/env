(show-paren-mode 1)

;; https://www.emacswiki.org/emacs/DeleteSelectionMode 
(delete-selection-mode 1)

;; store all backup and autosave files in the tmp dir
(let ((backup-dir "~/.emacs.d/auto-backup-list/")
      (auto-saves-dir "~/.emacs.d/auto-save-list/"))
  (dolist (dir (list backup-dir auto-saves-dir))
    (when (not (file-directory-p dir))
      (make-directory dir t)))
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,auto-saves-dir t))
        auto-save-list-file-prefix (concat auto-saves-dir ".saves-")))

(setq backup-by-copying t    ; Don't delink hardlinks                           
      delete-old-versions t  ; Clean up the backups                             
      version-control t      ; Use version numbers on backups,                  
      kept-new-versions 5    ; keep some new versions                           
      kept-old-versions 2)   ; and some old ones, too

 
