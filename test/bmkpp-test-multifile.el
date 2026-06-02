;;; bmkpp-test-multifile.el --- Multiple bookmark files   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(ert-deftest bmkpp-test-multifile/switch-replaces-alist ()
  "Switching to another bookmark file replaces `bookmark-alist'."
  (bmkpp-test-with-clean-bookmarks
    (let ((file-a bookmark-default-file)
          (file-b (bmkpp-test--make-temp-bookmark-file)))
      ;; Populate file A.
      (bmkpp-test-with-fixture-buffer buf "x"
        (bmkpp-test--make-bookmark "in-a" buf))
      (bookmark-write-file file-a)
      ;; Populate file B (fresh alist), write.
      (let ((bookmark-alist nil))
        (bmkpp-test-with-fixture-buffer buf "x"
          (bmkpp-test--make-bookmark "in-b" buf))
        (bookmark-write-file file-b))
      ;; Load A: confirm we have "in-a", not "in-b".
      (setq bookmark-alist nil)
      (let ((bookmarks-already-loaded nil))
        (bmkp-load file-a 'OVERWRITE 'NO-MSG))
      (should (bmkp-get-bookmark "in-a" 'NOERROR))
      (should-not (bmkp-get-bookmark "in-b" 'NOERROR)))))

(ert-deftest bmkpp-test-multifile/load-accumulates ()
  "Loading a second bookmark file without OVERWRITE accumulates records."
  (bmkpp-test-with-clean-bookmarks
    (let ((file-a bookmark-default-file)
          (file-b (bmkpp-test--make-temp-bookmark-file)))
      (bmkpp-test-with-fixture-buffer buf "x"
        (bmkpp-test--make-bookmark "from-a" buf))
      (bookmark-write-file file-a)
      (let ((bookmark-alist nil))
        (bmkpp-test-with-fixture-buffer buf "x"
          (bmkpp-test--make-bookmark "from-b" buf))
        (bookmark-write-file file-b))
      (setq bookmark-alist nil)
      (let ((bookmarks-already-loaded nil))
        (bmkp-load file-a 'OVERWRITE 'NO-MSG)
        (bmkp-load file-b nil       'NO-MSG))
      (should (bmkp-get-bookmark "from-a" 'NOERROR))
      (should (bmkp-get-bookmark "from-b" 'NOERROR)))))

(ert-deftest bmkpp-test-multifile/empty-file-bookmark-write ()
  "Writing the current alist to a new file produces a loadable file."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "writer" buf))
    (let ((other (bmkpp-test--make-temp-bookmark-file)))
      (bookmark-write-file other)
      (should (file-exists-p other))
      (let ((bookmark-alist nil)
            (bookmarks-already-loaded nil))
        (bmkp-load other 'OVERWRITE 'NO-MSG)
        (should (bmkp-get-bookmark "writer" 'NOERROR))))))


(provide 'bmkpp-test-multifile)
;;; bmkpp-test-multifile.el ends here
