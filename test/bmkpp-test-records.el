;;; bmkpp-test-records.el --- Bookmark record creation and identity   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(ert-deftest bmkpp-test-records/set-stores-record ()
  "`bookmark-set' stores a record retrievable by `bmkp-get-bookmark'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hello world"
      (bmkpp-test--make-bookmark "test-set" buf 7))
    (let ((rec (bmkp-get-bookmark "test-set" 'NOERROR)))
      (should rec)
      (should (equal (car rec) "test-set")))))

(ert-deftest bmkpp-test-records/record-has-id ()
  "Every newly-created record carries an `id' property."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "hello"
      (bmkpp-test--make-bookmark "with-id" buf))
    (let ((id (bookmark-prop-get "with-id" 'id)))
      (should (stringp id))
      (should (> (length id) 0)))))

(ert-deftest bmkpp-test-records/ids-are-unique ()
  "Two distinct bookmarks have distinct ids."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "ab"
      (bmkpp-test--make-bookmark "id-a" buf 1)
      (bmkpp-test--make-bookmark "id-b" buf 2))
    (let ((id-a (bookmark-prop-get "id-a" 'id))
          (id-b (bookmark-prop-get "id-b" 'id)))
      (should id-a)
      (should id-b)
      (should-not (equal id-a id-b)))))

(ert-deftest bmkpp-test-records/get-by-id-finds-record ()
  "`bmkp-get-by-id' returns the record matching an id."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "by-id" buf))
    (let* ((id  (bookmark-prop-get "by-id" 'id))
           (rec (bmkp-get-by-id id)))
      (should rec)
      (should (equal (car rec) "by-id")))))

(ert-deftest bmkpp-test-records/get-by-id-unknown-returns-nil ()
  "`bmkp-get-by-id' returns nil when the id does not exist."
  (bmkpp-test-with-clean-bookmarks
    (should-not (bmkp-get-by-id "no-such-id-xxxxxxxx"))))

(ert-deftest bmkpp-test-records/duplicate-name-auto-disambiguates ()
  "Re-creating a bookmark with no-overwrite yields a renamed sibling.

The contract: `bmkp-store NAME ... no-overwrite' creates a NEW
bookmark whose name is auto-renamed (e.g. `foo<2>') so both records
coexist."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "ab"
      (with-current-buffer buf
        (let ((bookmark-make-record-function #'bmkp-make-record-default))
          (goto-char 1)
          (bmkp-store "dup" (cdr (bookmark-make-record)) 'no-overwrite 'NO-REFRESH 'NO-MSG)
          (goto-char 2)
          (bmkp-store "dup" (cdr (bookmark-make-record)) 'no-overwrite 'NO-REFRESH 'NO-MSG))))
    (should (= 2 (length bookmark-alist)))
    (let ((names (mapcar #'car bookmark-alist)))
      (should (member "dup" names))
      (should (cl-some (lambda (n) (string-match-p "dup<[0-9]+>" n)) names)))))

(ert-deftest bmkpp-test-records/delete-removes-record ()
  "`bookmark-delete' removes the record from `bookmark-alist'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "del-me" buf))
    (should (bmkp-get-bookmark "del-me" 'NOERROR))
    (bookmark-delete "del-me")
    (should-not (bmkp-get-bookmark "del-me" 'NOERROR))))

(ert-deftest bmkpp-test-records/rename-preserves-id ()
  "Renaming a bookmark preserves its `id'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "before" buf))
    (let ((id-before (bookmark-prop-get "before" 'id)))
      (bookmark-rename "before" "after")
      (let ((id-after (bookmark-prop-get "after" 'id)))
        (should (equal id-before id-after))))))

(provide 'bmkpp-test-records)
;;; bmkpp-test-records.el ends here
