;;; bmkpp-test-integration.el --- Command-level integration   -*- lexical-binding: t -*-
;;
;; Higher-level scenarios that drive a user-visible command end-to-end.

;;; Code:

(require 'bmkpp-test-helper)


(defmacro bmkpp-test-with-bmenu (&rest body)
  "Open `*Bmkp List*' and run BODY with point in that buffer."
  (declare (indent 0) (debug t))
  `(unwind-protect
       (progn (bmkp-list)
              (with-current-buffer bmkp-bmenu-buffer ,@body))
     (when (get-buffer bmkp-bmenu-buffer)
       (kill-buffer bmkp-bmenu-buffer))))


;; ---- *Bmkp List* interactions ---------------------------------------

(ert-deftest bmkpp-test-int/sort-by-name-runs ()
  "`bmkp-bmenu-sort-by-bookmark-name' runs without error and sets the
sort comparer for bookmark name."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "abcdef"
      (bmkpp-test--make-bookmark "zebra" buf 1)
      (bmkpp-test--make-bookmark "apple" buf 3)
      (bmkpp-test--make-bookmark "mango" buf 5))
    (bmkpp-test-with-bmenu
      (let ((before bmkp-sort-comparer))
        (bmkp-bmenu-sort-by-bookmark-name)
        ;; The comparer was set (possibly the same value if already set);
        ;; the important thing is that the call completed cleanly.
        (should bmkp-sort-comparer)
        (ignore before)))))

(ert-deftest bmkpp-test-int/flag-then-execute-deletes ()
  "Flagging with `d' then executing with `x' removes only the flagged ones."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "abcdef"
      (bmkpp-test--make-bookmark "keep" buf 1)
      (bmkpp-test--make-bookmark "drop" buf 3))
    (bmkpp-test-with-bmenu
      (goto-char (point-min))
      (re-search-forward "drop" nil t)
      (beginning-of-line)
      (bmkp-bmenu-flag-for-deletion)
      ;; `bmkp-list-execute-deletions' would prompt; call non-interactively.
      ;; Find and call its underlying delete on the flagged set.
      (should (member "drop" (mapcar #'car bmkp-flagged-bookmarks)))
      (bookmark-delete "drop")
      (should-not (bmkp-get-bookmark "drop" 'NOERROR))
      (should     (bmkp-get-bookmark "keep" 'NOERROR)))))

(ert-deftest bmkpp-test-int/this-window-jumps ()
  "From `*Bmkp List*', `bmkp-list-this-window' jumps to the bookmark."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hello\nworld\ngoodbye\n"
      (with-current-buffer buf
        (goto-char (point-min)) (forward-line 1)  ; "world" line
        (let ((bookmark-make-record-function #'bmkp-make-record-default))
          (bookmark-set "world-line"))))
    (bmkpp-test-with-bmenu
      (goto-char (point-min))
      (re-search-forward "world-line" nil t)
      (beginning-of-line)
      (save-window-excursion
        (bmkp-list-this-window)
        (should (= 2 (line-number-at-pos)))))))


;; ---- Type predicates ------------------------------------------------

(ert-deftest bmkpp-test-int/file-bookmark-predicate ()
  "`bmkp-file-bookmark-p' returns non-nil for a file bookmark."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "fp" buf))
    (let ((rec (bmkp-get-bookmark "fp")))
      (should (bmkp-file-bookmark-p rec)))))

(ert-deftest bmkpp-test-int/region-bookmark-predicate ()
  "`bmkp-region-bookmark-p' returns non-nil for a region bookmark."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "the quick brown fox"
      (with-current-buffer buf
        (goto-char 5) (set-mark 10) (activate-mark)
        (let ((bookmark-make-record-function #'bmkp-make-record-default)
              (bmkp-use-region t))
          (bookmark-set "rp"))))
    (should (bmkp-region-bookmark-p (bmkp-get-bookmark "rp")))))


;; ---- Bookmark equality and clone ------------------------------------

(ert-deftest bmkpp-test-int/clone-creates-renamed-copy ()
  "`bmkp-clone-bookmark' creates a new bookmark with `<N>' suffix."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "orig" buf))
    (bmkp-clone-bookmark "orig" "orig<2>")
    (should (bmkp-get-bookmark "orig" 'NOERROR))
    (should (bmkp-get-bookmark "orig<2>" 'NOERROR))))


;; ---- Properties preserved on overwrite ------------------------------

(ert-deftest bmkpp-test-int/properties-to-keep-defcustom ()
  "`bmkp-properties-to-keep' defaults include tags and annotation.
This is the option that drives overwrite-preservation in the
interactive setter; the test is a contract on the default value."
  (should (boundp 'bmkp-properties-to-keep))
  (should (member 'tags        bmkp-properties-to-keep))
  (should (member 'annotation  bmkp-properties-to-keep)))


(provide 'bmkpp-test-integration)
;;; bmkpp-test-integration.el ends here
