;;; bmkpp-test-bmenu.el --- *Bmkp List* buffer   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(defmacro bmkpp-test-with-bmenu (&rest body)
  "Open `*Bmkp List*' and run BODY with point in that buffer.
Cleans up the buffer at exit."
  (declare (indent 0) (debug t))
  `(unwind-protect
       (progn (bmkp-list)
              (with-current-buffer bmkp-bmenu-buffer ,@body))
     (when (get-buffer bmkp-bmenu-buffer)
       (kill-buffer bmkp-bmenu-buffer))))


(ert-deftest bmkpp-test-bmenu/list-creates-buffer ()
  "`bmkp-list' creates the `*Bmkp List*' buffer."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "show" buf))
    (bmkpp-test-with-bmenu
      (should (get-buffer bmkp-bmenu-buffer))
      (should (eq major-mode 'bmkp-list-mode)))))

(ert-deftest bmkpp-test-bmenu/shows-bookmark-names ()
  "The buffer renders each bookmark on its own line."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "one" buf)
      (bmkpp-test--make-bookmark "two" buf)
      (bmkpp-test--make-bookmark "three" buf))
    (bmkpp-test-with-bmenu
      (let ((text (buffer-substring-no-properties (point-min) (point-max))))
        (should (string-match-p "\\bone\\b"   text))
        (should (string-match-p "\\btwo\\b"   text))
        (should (string-match-p "\\bthree\\b" text))))))

(ert-deftest bmkpp-test-bmenu/refresh-still-renders ()
  "`bmkp-bmenu-refresh-menu-list' rebuilds the display without error."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "r1" buf))
    (bmkpp-test-with-bmenu
      (bmkp-bmenu-refresh-menu-list)
      (let ((text (buffer-substring-no-properties (point-min) (point-max))))
        (should (string-match-p "r1" text))))))

(ert-deftest bmkpp-test-bmenu/mark-and-unmark ()
  "Marking with `>' updates `bmkp-bmenu-marked-bookmarks'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "mk" buf))
    (bmkpp-test-with-bmenu
      (goto-char (point-min))
      (re-search-forward "mk" nil t)
      (beginning-of-line)
      (bmkp-list-mark)
      (should (member "mk" bmkp-bmenu-marked-bookmarks))
      ;; Now unmark.
      (goto-char (point-min))
      (re-search-forward "mk" nil t)
      (beginning-of-line)
      (bmkp-list-unmark)
      (should-not (member "mk" bmkp-bmenu-marked-bookmarks)))))

(ert-deftest bmkpp-test-bmenu/list-bookmark-returns-current-name ()
  "`bmkp-list-bookmark' returns the bookmark name at point."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "current-line" buf))
    (bmkpp-test-with-bmenu
      (goto-char (point-min))
      (re-search-forward "current-line" nil t)
      (should (equal "current-line" (bmkp-list-bookmark))))))


(provide 'bmkpp-test-bmenu)
;;; bmkpp-test-bmenu.el ends here
