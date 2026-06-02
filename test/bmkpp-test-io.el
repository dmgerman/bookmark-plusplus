;;; bmkpp-test-io.el --- Bookmark-file write / read round-trip   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(ert-deftest bmkpp-test-io/round-trip-name-and-filename ()
  "Writing then reading the bookmark file preserves name and filename."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hello world"
      (bmkpp-test--make-bookmark "rt-one" buf 7))
    (bookmark-save)
    (let ((before bookmark-alist))
      ;; Fresh slate, reload from disk.
      (setq bookmark-alist nil)
      (let ((bookmarks-already-loaded nil))
        (bookmark-load bookmark-default-file 'OVERWRITE 'NO-MSG))
      (let ((after (bmkp-get-bookmark "rt-one" 'NOERROR)))
        (should after)
        (should (equal (bookmark-prop-get "rt-one" 'filename)
                       (bookmark-prop-get (car before) 'filename)))))))

(ert-deftest bmkpp-test-io/round-trip-preserves-id ()
  "Reloading a bookmark file preserves each record's `id'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hi"
      (bmkpp-test--make-bookmark "rt-id" buf))
    (let ((id-before (bookmark-prop-get "rt-id" 'id)))
      (bookmark-save)
      (setq bookmark-alist nil)
      (let ((bookmarks-already-loaded nil))
        (bookmark-load bookmark-default-file 'OVERWRITE 'NO-MSG))
      (should (equal id-before (bookmark-prop-get "rt-id" 'id))))))

(ert-deftest bmkpp-test-io/round-trip-preserves-tags ()
  "Reloading a bookmark file preserves tags."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hi"
      (bmkpp-test--make-bookmark "rt-tags" buf)
      (bmkp-add-tags "rt-tags" '("alpha" "beta") 'NO-UPDATE-P 'NO-MSG-P))
    (bookmark-save)
    (setq bookmark-alist nil)
    (let ((bookmarks-already-loaded nil))
      (bookmark-load bookmark-default-file 'OVERWRITE 'NO-MSG))
    (let ((tags (bmkp-get-tags "rt-tags")))
      (should (member "alpha" (mapcar (lambda (tt) (if (consp tt) (car tt) tt)) tags)))
      (should (member "beta"  (mapcar (lambda (tt) (if (consp tt) (car tt) tt)) tags))))))

(ert-deftest bmkpp-test-io/load-backfills-missing-ids ()
  "Loading a bookmark file with id-less records adds an `id' to each.

This simulates a file written by built-in `bookmark.el' or by older
Bookmark+ versions."
  (bmkpp-test-with-clean-bookmarks
    (let ((tmp (bmkpp-test--make-temp-bookmark-file))
          (txt (make-temp-file "bmkpp-test-load-" nil ".txt")))
      (push txt bmkpp-test--temp-files)
      (with-temp-file txt (insert "xyz"))
      ;; Hand-write a bookmark file without an `id' field.
      (with-temp-file tmp
        (insert ";;;; Emacs Bookmark Format Version 1 -*- coding: utf-8-emacs-unix -*-\n")
        (insert ";;; -*- End Of Bookmark File Format Version Stamp -*-\n")
        (prin1 `(("no-id"
                  (filename . ,txt)
                  (position . 1)))
               (current-buffer))
        (insert "\n"))
      (let ((bookmark-default-file tmp)
            (bookmarks-already-loaded nil)
            (bookmark-alist nil))
        ;; `bmkp-load' runs the post-load hooks (id backfill, dedup);
        ;; built-in `bookmark-load' does not.
        (bmkp-load tmp 'OVERWRITE 'NO-MSG)
        (let ((id (bookmark-prop-get "no-id" 'id)))
          (should (stringp id))
          (should (> (length id) 0)))))))

(ert-deftest bmkpp-test-io/load-deduplicates-names ()
  "Loading a bookmark file with duplicate names yields unique names.

Bmkp-deduplicate-bookmark-names runs on the post-load hook and renames
the second occurrence (foo -> foo<2>)."
  (bmkpp-test-with-clean-bookmarks
    (let ((tmp (bmkpp-test--make-temp-bookmark-file))
          (txt (make-temp-file "bmkpp-test-dedup-" nil ".txt")))
      (push txt bmkpp-test--temp-files)
      (with-temp-file txt (insert "hi"))
      (with-temp-file tmp
        (insert ";;;; Emacs Bookmark Format Version 1 -*- coding: utf-8-emacs-unix -*-\n")
        (insert ";;; -*- End Of Bookmark File Format Version Stamp -*-\n")
        (prin1 `(("foo" (filename . ,txt) (position . 1))
                 ("foo" (filename . ,txt) (position . 2)))
               (current-buffer))
        (insert "\n"))
      (let ((bookmark-default-file tmp)
            (bookmarks-already-loaded nil)
            (bookmark-alist nil))
        (bmkp-load tmp 'OVERWRITE 'NO-MSG)
        (should (= 2 (length bookmark-alist)))
        (let ((names (mapcar #'car bookmark-alist)))
          (should (member "foo" names))
          (should (cl-some (lambda (n) (string-match-p "foo<[0-9]+>" n)) names)))))))


(provide 'bmkpp-test-io)
;;; bmkpp-test-io.el ends here
