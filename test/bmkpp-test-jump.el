;;; bmkpp-test-jump.el --- Jump dispatch   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(ert-deftest bmkpp-test-jump/file-bookmark-visits-file ()
  "Jumping to a file bookmark visits the file and lands at the recorded position."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "line one\nline two\nline three\n"
      (with-current-buffer buf
        (goto-char (point-min))
        (forward-line 1)
        (let ((bookmark-make-record-function #'bmkp-make-record-default))
          (bookmark-set "line2-bmk")))
      (kill-buffer buf))
    (bmkp-jump "line2-bmk")
    (should (string= "line one\nline two\nline three\n"
                     (buffer-substring-no-properties (point-min) (point-max))))
    (should (= (line-number-at-pos) 2))))

(ert-deftest bmkpp-test-jump/region-bookmark-activates-region ()
  "Jumping to a region bookmark activates the region between start and end."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "the quick brown fox"
      (with-current-buffer buf
        (goto-char 5)                   ; "quick" start
        (set-mark 10)                   ; "quick" end
        (activate-mark)
        (let ((bookmark-make-record-function #'bmkp-make-record-default)
              (bmkp-use-region t))
          (bookmark-set "quick-region")))
      (kill-buffer buf))
    (let ((bmkp-use-region t))
      (bmkp-jump "quick-region"))
    (should mark-active)
    (should (or (= (mark) 5)  (= (point) 5)))
    (should (or (= (mark) 10) (= (point) 10)))))

(ert-deftest bmkpp-test-jump/unknown-bookmark-signals ()
  "Jumping to a non-existent bookmark signals an error."
  (bmkpp-test-with-clean-bookmarks
    (should-error (bmkp-jump "no-such-bookmark"))))

(ert-deftest bmkpp-test-jump/bookmark-name-from-record ()
  "`bookmark-name-from-full-record' returns the bookmark's name."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "h" buf))
    (let ((rec (assoc "h" bookmark-alist)))
      (should (equal "h" (bookmark-name-from-full-record rec))))))

(ert-deftest bmkpp-test-jump/visit-increments-counter ()
  "Jumping to a bookmark increments its `visits' counter."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "visit-counter" buf))
    (let ((before (or (bookmark-prop-get "visit-counter" 'visits) 0)))
      (bmkp-jump "visit-counter")
      (let ((after (bookmark-prop-get "visit-counter" 'visits)))
        (should after)
        (should (> after before))))))


(provide 'bmkpp-test-jump)
;;; bmkpp-test-jump.el ends here
