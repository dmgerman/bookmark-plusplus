;;; run-tests.el --- Load every bmkpp test file   -*- lexical-binding: t -*-

;;; Code:

(require 'bmkpp-test-helper)

(dolist (f (directory-files (file-name-directory load-file-name) t
                            "\\`bmkpp-test-.*\\.el\\'"))
  (unless (string-match-p "test-helper" f)
    (load f nil 'nomessage)))

(provide 'run-tests)
;;; run-tests.el ends here
