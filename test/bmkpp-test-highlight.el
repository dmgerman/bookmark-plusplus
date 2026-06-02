;;; bmkpp-test-highlight.el --- Persistent bookmark highlighting   -*- lexical-binding: t -*-
;;
;; These tests exercise `bookmark+-lit.el'.  They are skipped if the
;; library is not loaded.

;;; Code:

(require 'bmkpp-test-helper)


(defmacro bmkpp-test-skip-unless-lit (&rest body)
  "Run BODY only if `bookmark+-lit' is loaded."
  (declare (indent 0) (debug t))
  `(if (featurep 'bookmark+-lit)
       (progn ,@body)
     (ert-skip "bookmark+-lit not loaded")))


(defun bmkpp-test--overlays-for-bookmark (file name)
  "Return all `bookmark-plus' overlays in FILE's buffer tagged with NAME."
  (let ((dest (find-file-noselect file)))
    (with-current-buffer dest
      (cl-remove-if-not
       (lambda (ov)
         (let ((bmk (overlay-get ov 'bookmark)))
           (and (eq 'bookmark-plus (overlay-get ov 'category))
                (consp bmk)
                (equal name (car bmk)))))
       (overlays-in (point-min) (point-max))))))

(ert-deftest bmkpp-test-highlight/light-adds-overlay ()
  "Lighting a bookmark adds at least one overlay in the destination buffer."
  (bmkpp-test-skip-unless-lit
    (bmkpp-test-with-clean-bookmarks
      (bmkpp-test-with-fixture-buffer buf "alpha beta gamma"
        (let ((file (buffer-file-name buf)))
          (bmkpp-test--make-bookmark "lit-target" buf 7)
          (bmkp-light-bookmark "lit-target")
          (should (bmkpp-test--overlays-for-bookmark file "lit-target")))))))

(ert-deftest bmkpp-test-highlight/unlight-removes-overlay ()
  "Unlighting a bookmark removes its overlay."
  (bmkpp-test-skip-unless-lit
    (bmkpp-test-with-clean-bookmarks
      (bmkpp-test-with-fixture-buffer buf "alpha beta gamma"
        (let ((file (buffer-file-name buf)))
          (bmkpp-test--make-bookmark "lit-rm" buf 7)
          (bmkp-light-bookmark "lit-rm")
          (should     (bmkpp-test--overlays-for-bookmark file "lit-rm"))
          (bmkp-unlight-bookmark "lit-rm")
          (should-not (bmkpp-test--overlays-for-bookmark file "lit-rm")))))))

(ert-deftest bmkpp-test-highlight/light-records-style-override ()
  "Setting a per-bookmark lighting style stores a `lighting' property."
  (bmkpp-test-skip-unless-lit
    (bmkpp-test-with-clean-bookmarks
      (bmkpp-test-with-fixture-buffer buf "x"
        (bmkpp-test--make-bookmark "ovr" buf))
      ;; `bmkp-set-lighting-for-bookmark' is interactive; call it via the
      ;; setter helpers it uses internally.
      (let ((rec (bmkp-get-bookmark "ovr")))
        (bookmark-prop-set rec 'lighting '(:style line :face nil)))
      (should (bmkp-get-lighting "ovr")))))


(provide 'bmkpp-test-highlight)
;;; bmkpp-test-highlight.el ends here
