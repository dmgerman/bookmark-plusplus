;;; bmkpp-test-helper.el --- Shared helpers for the test suite   -*- lexical-binding: t -*-
;;
;; Every test goes through `bmkpp-test-with-clean-bookmarks', which:
;;   - rebinds `bookmark-alist' to nil,
;;   - rebinds `bookmark-default-file' to a unique temp file,
;;   - rebinds `bookmark-save-flag' to nil (no auto-save),
;;   - rebinds the bmkp-bmenu state file so it can't leak,
;;   - cleans up the temp file on exit.
;;
;; The user's real bookmarks are never touched.

;;; Code:

(require 'ert)
(require 'bookmark+)

(defvar bmkpp-test--temp-files nil
  "Temp bookmark files created in the current test run, for cleanup.")

(defun bmkpp-test--make-temp-bookmark-file ()
  "Return a unique bookmark-file path with no file at it yet.
Registered for cleanup.

We use `make-temp-name' (not `make-temp-file') so the path exists but
the file does not, which lets `bookmark-set' create it from scratch
without first trying to load garbage from an empty file."
  (let ((f  (make-temp-name
             (expand-file-name "bmkpp-test-" temporary-file-directory))))
    (push f bmkpp-test--temp-files)
    f))

(defmacro bmkpp-test-with-clean-bookmarks (&rest body)
  "Run BODY with a fresh, isolated bookmark environment.
Inside BODY:
  - `bookmark-alist' starts at nil.
  - `bookmark-default-file' is a fresh temp file.
  - `bookmark-save-flag' is nil (no auto-save).
  - `bmkp-bmenu-state-file' is nil (no state leak)."
  (declare (indent 0) (debug t))
  `(let* ((bmkpp-test--temp-files  nil)
          (tmp                    (bmkpp-test--make-temp-bookmark-file))
          (bookmark-alist         nil)
          (bookmark-default-file  tmp)
          (bookmark-save-flag     nil)
          (bookmark-current-file  tmp)
          (bmkp-bmenu-state-file  nil)
          (bmkp-current-bookmark-file  tmp)
          (bmkp-last-bookmark-file     tmp)
          (bmkp-last-as-first-bookmark-file  nil)
          (bookmark-bookmarks-timestamp  nil)
          (bookmarks-already-loaded      nil))
     (unwind-protect
         (progn ,@body)
       (dolist (f bmkpp-test--temp-files)
         (when (and f (file-exists-p f)) (delete-file f))))))

(defun bmkpp-test--fresh-file-buffer (text)
  "Write TEXT to a fresh temp file and visit it.  Return the buffer.
The file is registered for cleanup; caller is responsible for
`kill-buffer'."
  (let ((f  (make-temp-file "bmkpp-test-fix-" nil ".txt")))
    (push f bmkpp-test--temp-files)
    (with-temp-file f (insert text))
    (find-file-noselect f)))

(defmacro bmkpp-test-with-fixture-buffer (var text &rest body)
  "Bind VAR to a fresh file-visiting buffer containing TEXT.
Run BODY.  Kill the buffer (and delete the file) at exit."
  (declare (indent 2) (debug t))
  `(let ((,var (bmkpp-test--fresh-file-buffer ,text)))
     (unwind-protect (progn ,@body)
       (when (buffer-live-p ,var) (kill-buffer ,var)))))

(defun bmkpp-test--make-bookmark (name buffer &optional position)
  "Set a bookmark named NAME at POSITION (default: point-min) in BUFFER.
Uses the bmkp-aware setter so the record gets the `id' field.
Return the stored bookmark record."
  (with-current-buffer buffer
    (save-excursion
      (goto-char (or position (point-min)))
      (let ((bookmark-make-record-function #'bmkp-make-record-default))
        (bookmark-set name))))
  (bmkp-get-bookmark name 'NOERROR))

(provide 'bmkpp-test-helper)
;;; bmkpp-test-helper.el ends here
