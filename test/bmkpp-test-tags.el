;;; bmkpp-test-tags.el --- Tag operations   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)


(defun bmkpp-test--tag-names (bmk)
  "Return tag names (strings) for BMK, ignoring values."
  (mapcar (lambda (tt) (if (consp tt) (car tt) tt))
          (bmkp-get-tags bmk)))


(ert-deftest bmkpp-test-tags/add-and-list ()
  "Tags added with `bmkp-add-tags' appear in `bmkp-get-tags'."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "tag-add" buf))
    (bmkp-add-tags "tag-add" '("a" "b" "c") 'NO-UPDATE-P 'NO-MSG-P)
    (let ((tags (bmkpp-test--tag-names "tag-add")))
      (should (member "a" tags))
      (should (member "b" tags))
      (should (member "c" tags))
      (should (= 3 (length tags))))))

(ert-deftest bmkpp-test-tags/remove ()
  "`bmkp-remove-tags' removes a tag from a bookmark."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "tag-rm" buf))
    (bmkp-add-tags "tag-rm" '("a" "b") 'NO-UPDATE-P 'NO-MSG-P)
    (bmkp-remove-tags "tag-rm" '("a") 'NO-UPDATE-P 'NO-MSG-P)
    (let ((tags (bmkpp-test--tag-names "tag-rm")))
      (should-not (member "a" tags))
      (should     (member "b" tags)))))

(ert-deftest bmkpp-test-tags/add-twice-is-idempotent ()
  "Adding the same tag twice does not duplicate it."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "idemp" buf))
    (bmkp-add-tags "idemp" '("foo") 'NO-UPDATE-P 'NO-MSG-P)
    (bmkp-add-tags "idemp" '("foo") 'NO-UPDATE-P 'NO-MSG-P)
    (should (= 1 (length (bmkp-get-tags "idemp"))))))

(ert-deftest bmkpp-test-tags/tag-with-value ()
  "A tag stored as (NAME . VALUE) carries its value."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "x"
      (bmkpp-test--make-bookmark "valued" buf))
    (bmkp-add-tags "valued" (list (cons "color" "blue")) 'NO-UPDATE-P 'NO-MSG-P)
    (should (equal "blue" (bmkp-get-tag-value "valued" "color")))))

(ert-deftest bmkpp-test-tags/list-all-tags ()
  "`bmkp-tags-list' aggregates tags across bookmarks."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "abcdef"
      (bmkpp-test--make-bookmark "all-a" buf 1)
      (bmkpp-test--make-bookmark "all-b" buf 5))
    (should (= 2 (length bookmark-alist)))
    (bmkp-add-tags "all-a" '("alpha" "shared") 'NO-UPDATE-P 'NO-MSG-P)
    (bmkp-add-tags "all-b" '("beta"  "shared") 'NO-UPDATE-P 'NO-MSG-P)
    (let ((all (mapcar #'car (bmkp-tags-list))))
      (should (member "alpha"  all))
      (should (member "beta"   all))
      (should (member "shared" all)))))

(ert-deftest bmkpp-test-tags/rename ()
  "`bmkp-rename-tag' renames the tag in every bookmark that has it."
  (bmkpp-test-with-clean-bookmarks
    (bmkpp-test-with-fixture-buffer buf "abcdef"
      (bmkpp-test--make-bookmark "rn-a" buf 1)
      (bmkpp-test--make-bookmark "rn-b" buf 5))
    (bmkp-add-tags "rn-a" '("old") 'NO-UPDATE-P 'NO-MSG-P)
    (bmkp-add-tags "rn-b" '("old") 'NO-UPDATE-P 'NO-MSG-P)
    (bmkp-rename-tag "old" "new")
    (should (member "new" (bmkpp-test--tag-names "rn-a")))
    (should (member "new" (bmkpp-test--tag-names "rn-b")))
    (should-not (member "old" (bmkpp-test--tag-names "rn-a")))
    (should-not (member "old" (bmkpp-test--tag-names "rn-b")))))


(provide 'bmkpp-test-tags)
;;; bmkpp-test-tags.el ends here
