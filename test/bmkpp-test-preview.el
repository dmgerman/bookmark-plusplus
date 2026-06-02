;;; bmkpp-test-preview.el --- bmkp-list-preview-mode   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(ert-deftest bmkpp-test-preview/mode-defined ()
  "`bmkp-list-preview-mode' is defined."
  (should (fboundp 'bmkp-list-preview-mode)))

(ert-deftest bmkpp-test-preview/mode-toggles ()
  "Toggling the mode sets and unsets the variable."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "p1" buf))
    (unwind-protect
        (progn
          (bmkp-list)
          (with-current-buffer bmkp-bmenu-buffer
            (should-not bmkp-list-preview-mode)
            (bmkp-list-preview-mode 1)
            (should bmkp-list-preview-mode)
            (bmkp-list-preview-mode -1)
            (should-not bmkp-list-preview-mode)))
      (when (get-buffer bmkp-bmenu-buffer)
        (kill-buffer bmkp-bmenu-buffer)))))

(ert-deftest bmkpp-test-preview/lighter-present-when-active ()
  "The mode-line lighter `\" Pv\"' appears when the mode is on."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "p2" buf))
    (unwind-protect
        (progn
          (bmkp-list)
          (with-current-buffer bmkp-bmenu-buffer
            (bmkp-list-preview-mode 1)
            (let ((lighter (assq 'bmkp-list-preview-mode minor-mode-alist)))
              (should lighter)
              (should (string-match-p "Pv" (or (cadr lighter) ""))))))
      (when (get-buffer bmkp-bmenu-buffer)
        (kill-buffer bmkp-bmenu-buffer)))))

(ert-deftest bmkpp-test-preview/consult-jump-reader-defined ()
  "`bmkp-read-bookmark-for-jump' is defined."
  (should (fboundp 'bmkp-read-bookmark-for-jump)))

(ert-deftest bmkpp-test-preview/consult-flag-default ()
  "`bmkp-preview-use-consult-flag' is t by default."
  (should (boundp 'bmkp-preview-use-consult-flag))
  (should bmkp-preview-use-consult-flag))


(provide 'bmkpp-test-preview)
;;; bmkpp-test-preview.el ends here
