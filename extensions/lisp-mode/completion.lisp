(defpackage :lem-lisp-mode/completion
  (:use :cl :lem-lisp-mode/internal)
  (:export :make-completions-form-string
           :eval-completions
           :make-completion-items
           :symbol-completion
           :region-completion))
(in-package :lem-lisp-mode/completion)

(defun make-completions-form-string (string package-name)
  (format nil
          "(micros/lsp-api:completions ~S ~S)"
          string
          package-name))

(defun eval-completions (string package)
  (lisp-eval-from-string (make-completions-form-string string package)
                         "COMMON-LISP-USER"))

(defun make-completion-item* (completion &optional start end)
  (let ((label (micros/lsp-api::completed-item-label completion))
        (chunks (micros/lsp-api::completed-item-chunks completion))
        (detail (micros/lsp-api::completed-item-classification completion))
        (documentation (micros/lsp-api::completed-item-documentation completion)))
    (lem/completion-mode:make-completion-item
     :label label
     :chunks (loop :for (offset substring) :in chunks
                   :collect (cons offset (+ offset (length substring))))
     :detail detail
     :start start
     :end end
     :focus-action (lambda (context)
                     (unless (alexandria:emptyp documentation)
                       (lem:show-message (lem/markdown-buffer:markdown-buffer documentation)
                                         :style '(:gravity :vertically-adjacent-window-dynamic
                                                  :offset-y -1
                                                  :offset-x 1)
                                         :source-window (lem/popup-menu::popup-menu-window
                                                         (lem/completion-mode::context-popup-menu
                                                          context))))))))

(defun make-completion-items (completions &rest args)
  (mapcar (lambda (completion)
            (apply #'make-completion-item* completion args))
          completions))

(defun symbol-completion (string &optional (package (current-package)))
  (let ((completions (eval-completions string package)))
    (make-completion-items completions)))

(defun region-completion (start end &optional (package (current-package)))
  (let* ((completions (eval-completions (lem:points-to-string start end)
                                        package)))
    (make-completion-items completions start end)))
