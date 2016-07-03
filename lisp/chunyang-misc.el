;;; chunyang-misc.el --- Miscellaneous               -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; -----------------------------------------------------------------------------
;; Show recent project/file in a buffer
;;

;; The code requires Projectile and Recentf for their data.  Also, this idea is
;; inspired by Spacemacs's startup buffer, see <http://spacemacs.org/>.


(defun chunyang-insert-file-list (list-display-name list)
  ;; Copied from `spacemacs-buffer//insert-file-list'.
  (when (car list)
    (insert list-display-name)
    (mapc (lambda (el)
            (insert "\n    ")
            (widget-create 'push-button
                           :action `(lambda (&rest ignore) (find-file-existing ,el))
                           :mouse-face 'highlight
                           :follow-link "\C-m"
                           :button-prefix ""
                           :button-suffix ""
                           :format "%[%t%]"
                           (abbreviate-file-name el)))
          list)))

(defun chunyang-list-recentf-and-projects ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*Recentf & Project List*"))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (chunyang-insert-file-list "Recent Files:" (recentf-elements 5))
    (insert "\n\n")
    (chunyang-insert-file-list "Projects:" projectile-known-projects)
    (goto-char (point-min))
    (page-break-lines-mode)
    (read-only-mode))
  (local-set-key (kbd "RET") 'widget-button-press)
  (local-set-key [down-mouse-1] 'widget-button-click))


;; -----------------------------------------------------------------------------
;; Run-length
;;

;; https://en.wikipedia.org/wiki/Run-length_encoding

(defun run-length-encode (str)
  "Return Run-Length representation of STR as a string."
  (with-temp-buffer
    (let ((idx 0)
          (len (length str))
          this-char last-char occur)
      (while (< idx len)
        (let ((this-char (aref str idx)))
          (if (eq this-char last-char)
              (setq occur (+ 1 occur))
            (if last-char
                (insert (format "%d%c" occur last-char)))
            (setq last-char this-char
                  occur 1))
          (if (= (+ 1 idx) len)
              (insert (format "%d%c" occur last-char))))
        (setq idx (+ 1 idx))))
    (buffer-string)))

(defun run-length-decode (str)
  "Decode Run-Length representation."
  (with-temp-buffer
    (let ((idx 0)
          this-char occur char)
      (while (< idx (length str))
        (let ((this-char (aref str idx)))
          (if (< ?0 this-char ?9)
              (setq occur (concat occur (char-to-string this-char)))
            (setq char this-char)
            (insert (make-string (string-to-number occur) char))
            (setq occur nil)))
        (setq idx (+ 1 idx))))
    (buffer-string)))

;; -----------------------------------------------------------------------------
;; Fibonacci number
;;

;; 1 1 2 3 5 8 13 21 34 55 89 144 ...

(defun fib (n)
  (if (memq n '(1 2))
      1
    (+ (fib (- n 1))
       (fib (- n 2)))))

(defun fib-list (n)
  (let (last last-last this res)
    (dolist (i (number-sequence 1 n))
      (if (memq i '(1 2))
          (setq res (cons 1 res)
                last 1
                last-last 1)
        (let ((this (+ last last-last)))
          (setq res (cons this res)
                last-last last
                last this))))
    (nreverse res)))


;;; Format Emacs Lisp
(defun chunyang-one-space (beg end &optional query-p)
  "Keep only one blank space."
  (interactive "r\nP")
  (perform-replace "\\([^ \n] \\)\\( +\\)\\([^ \n]\\)"
                   (cons (lambda (_data _count)
                           (concat (match-string 1)
                                   (match-string 3)))
                         nil)
                   query-p 'regexp nil nil nil beg end))

(defun chunyang-zero-space (beg end &optional query-p)
  "Delete blank space after (."
  (interactive "r\nP")
  (perform-replace "(\\( +\\)" "(" query-p 'regexp nil nil nil beg end))

;; Also note C-u C-M-q


;;; Download and eval
(defun download-and-eval (url)
  (let ((f (expand-file-name (file-name-nondirectory url)
                             temporary-file-directory)))
    (url-copy-file url f)
    (load-file f)))


;; http://emacs.stackexchange.com/questions/20171/how-to-preserve-color-in-messages-buffer
(defun my-message (format &rest args)
  "Acts like `message' but preserves string properties in the *Messages* buffer."
  (let ((message-log-max nil))
    (apply 'message format args))
  (with-current-buffer (get-buffer "*Messages*")
    (save-excursion
      (goto-char (point-max))
      (let ((inhibit-read-only t))
        (unless (zerop (current-column)) (insert "\n"))
        (insert (apply 'format format args))
        (insert "\n")))))

;; Oops, the following *breaks* Emacs
;; (advice-add 'message :override #'my-message)

(provide 'chunyang-misc)
;;; chunyang-misc.el ends here
