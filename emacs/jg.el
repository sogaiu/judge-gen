;;; jg.el --- Wrapper for jg  -*- lexical-binding: t; -*-

;; Author: sogaiu
;; URL: https://github.com/sogaiu/judge-gen
;; Version: 0.1-pre
;; Package-Requires: ((emacs "25.2"))
;; Keywords: janet, repl, testing

;; This file is not part of GNU Emacs.

;;; Commentary:

;;

;;;; Installation

;;;;; Manual

;; Put this file in your load-path, and put this in your init file:

;; (require 'jg)

;; Customize the function used to hand the result of running jg to a
;; repl.  For example:

;; (setq jg-response-action (lambda (code-str) (ajsc-send-code code-str)))

;;;; Usage

;; With a repl connection established to a janet process and point
;; somewhere in Janet code, execute:

;; `jg-verify': run an appropriate set of expressions as tests

;;;; Todo

;; Factor out common bits of jg-verify*
;;
;; Provide a menu

;;; Code:

;;;; Requirements

(require 'files)
(require 'simple)

;;;;; Variables

;; XXX: should be some kind of local thing?
(defvar jg-temp-output
  '()
  "List to accumulate output from jg process.")

;; XXX: should be some kind of local thing?
(defvar jg-response-action
  (lambda (output-str)
    (message "response: %S" output-str))
  "Function that is handed the complete output from jg.")

;;;;; Commands

(defun jg-path ()
  "Determine path to jg binary."
  (concat (locate-dominating-file
           (symbol-file 'jg-temp-output)
           "jg.el")
          "../bin/jg"))

(defun jg-filter (process output)
  "Filter for processing jg command output."
  ;; XXX
  (message "filter: %S" output)
  (setq jg-temp-output
        (cons output jg-temp-output)))

(defun jg-reset-temp-output ()
  (setq jg-temp-output '()))

;; handles processing complete output from jg process
;; XXX: better to handle errors for cleanup, see:
;;   https://www.gnu.org/software/emacs/manual/html_node/elisp/Sentinels.html
(defun jg-sentinel (process event)
  "Sentinel for jg process."
  ;; XXX
  (message "event: %S" event)
  (when (equal "finished\n" event)
    (let* ((output-str (apply 'concat (reverse jg-temp-output))))
      (funcall jg-response-action output-str))
    (jg-reset-temp-output)))

(defun jg-get-buffer-text ()
  (buffer-substring-no-properties 1 (1+ (buffer-size))))

;;;###autoload
(defun jg-verify ()
  "Evalute a suitable set of expressions."
  (interactive)
  (condition-case err
      (let* ((jg-str (jg-get-buffer-text))
             (jg-proc (make-process :name "jg"
                                    :buffer nil
                                    :command (list (jg-path)
                                                   "-f" "text"
                                                   "-l"
                                                   (number-to-string
                                                    (line-number-at-pos))
                                                   )
                                    :connection-type 'pipe
                                    :filter 'jg-filter
                                    :sentinel 'jg-sentinel)))
        ;; XXX
        (message "jg-str: %S" jg-str)
        ;; XXX: both 'binary and 'utf-8 seem to cause problems...
        ;;(set-process-coding-system jg-proc 'binary)
        (when jg-proc
          ;; XXX: is this sufficient?
          (jg-reset-temp-output)
          (process-send-string jg-proc jg-str)
          (process-send-eof jg-proc)))
    (error
     (message "Error: %s %s" (car err) (cdr err)))))

;;;###autoload
(defun jg-verify-all ()
  "Evalute a suitable set of expressions."
  (interactive)
  (condition-case err
      (let* ((jg-str (jg-get-buffer-text))
             (jg-proc (make-process :name "jg"
                                    :buffer nil
                                    :command (list (jg-path)
                                                   "-f" "text"
                                                   "-n" "0")
                                    :connection-type 'pipe
                                    :filter 'jg-filter
                                    :sentinel 'jg-sentinel)))
        ;; XXX
        (message "jg-str: %S" jg-str)
        ;; XXX: both 'binary and 'utf-8 seem to cause problems...
        ;;(set-process-coding-system jg-proc 'binary)
        (when jg-proc
          ;; XXX: is this sufficient?
          (jg-reset-temp-output)
          (process-send-string jg-proc jg-str)
          (process-send-eof jg-proc)))
    (error
     (message "Error: %s %s" (car err) (cdr err)))))

;;;###autoload
(defun jg-verify-all-remaining ()
  "Evalute a suitable set of expressions."
  (interactive)
  (condition-case err
      (let* ((jg-str (jg-get-buffer-text))
             (jg-proc (make-process :name "jg"
                                    :buffer nil
                                    :command (list (jg-path)
                                                   "-f" "text"
                                                   "-n" "0"
                                                   "-l"
                                                   (number-to-string
                                                    (line-number-at-pos))
                                                   )
                                    :connection-type 'pipe
                                    :filter 'jg-filter
                                    :sentinel 'jg-sentinel)))
        ;; XXX
        (message "jg-str: %S" jg-str)
        ;; XXX: both 'binary and 'utf-8 seem to cause problems...
        ;;(set-process-coding-system jg-proc 'binary)
        (when jg-proc
          ;; XXX: is this sufficient?
          (jg-reset-temp-output)
          (process-send-string jg-proc jg-str)
          (process-send-eof jg-proc)))
    (error
     (message "Error: %s %s" (car err) (cdr err)))))

;;;; Footer

(provide 'jg)

;;; jg.el ends here

(defmacro comment (&rest body)
  "Comment out one or more s-expressions, i.e. BODY."
  nil)

(comment

 (setq test-str "(def a 1)\n\n:b")

 (setq test-str "(def a 1)\n(comment :a )\n:b")

 (progn
   (setq jg-proc
         (make-process :name "jg"
                       :command (list (jg-path)
                                      "-l"
                                      (number-to-string
                                       (line-number-at-pos))
                                      "-f" "text"
                                      )
                       :connection-type 'pipe
                       :filter 'jg-filter
                       :sentinel 'jg-sentinel))
   (process-send-string jg-proc test-str)
   (process-send-eof jg-proc)
   (jg-reset-temp-output))

)
