;;; casual-bmkp.el --- Casual Transient menus for Bookmark+   -*- lexical-binding:t -*-
;;
;; A discoverable Transient-based UI for the `*Bmkp List*' buffer, in
;; the style of the Casual suite (casual-info, casual-dired, ...).
;;
;; Hard-requires `casual-lib' so that its styling helpers and Unicode
;; symbols are available; the parent `bookmark+.el' loads this file
;; with a soft require, so if `casual-lib' is not installed the menu
;; simply does not appear and Bookmark+ runs unchanged.
;;
;; Activation:
;;
;;   When loaded, this file binds `casual-bmkp-tmenu' to `c' in
;;   `bmkp-list-mode-map'.  (Casual's own ecosystem uses `C-o' as the
;;   entry-point key, but in `bmkp-list-mode' `C-o' is already taken
;;   by `bmkp-list-switch-other-window' and `c' is otherwise free.)
;;
;; Commands are organised by intent: move, mark/unmark, delete,
;; filter/show, sort, edit, files, preview, help.  Sort is its own
;; submenu (there are too many sort orders to fit in the main menu).

;;; Code:

(require 'transient)
(require 'casual-lib)
(require 'bookmark)

;; Forward decls — bookmark+-bmu / bookmark+-1 / bookmark+-preview define these.
(declare-function bmkp-list-mark                                 "bookmark+-bmu")
(declare-function bmkp-list-unmark                               "bookmark+-bmu")
(declare-function bmkp-list-this-window                          "bookmark+-bmu")
(declare-function bmkp-list-other-window                         "bookmark+-bmu")
(declare-function bmkp-list-switch-other-window                  "bookmark+-bmu")
(declare-function bmkp-list-execute-deletions                    "bookmark+-bmu")
(declare-function bmkp-list-rename                               "bookmark+-bmu")
(declare-function bmkp-list-show-annotation                      "bookmark+-bmu")
(declare-function bmkp-list-toggle-filenames                     "bookmark+-bmu")
(declare-function bmkp-list-preview-mode                         "bookmark+-preview")
(declare-function bmkp-bmenu-flag-for-deletion                   "bookmark+-bmu")
(declare-function bmkp-bmenu-delete-marked                       "bookmark+-bmu")
(declare-function bmkp-bmenu-refresh-menu-list                   "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-all                            "bookmark+-bmu")
(declare-function bmkp-bmenu-unmark-all                          "bookmark+-bmu")
(declare-function bmkp-bmenu-toggle-marks                        "bookmark+-bmu")
(declare-function bmkp-bmenu-show-all                            "bookmark+-bmu")
(declare-function bmkp-bmenu-toggle-show-only-marked             "bookmark+-bmu")
(declare-function bmkp-bmenu-toggle-show-only-unmarked           "bookmark+-bmu")
(declare-function bmkp-bmenu-regexp-mark                         "bookmark+-bmu")
(declare-function bmkp-bmenu-edit-bookmark-record                "bookmark+-bmu")
(declare-function bmkp-bmenu-edit-marked                         "bookmark+-bmu")
(declare-function bmkp-bmenu-quit                                "bookmark+-bmu")
(declare-function bmkp-bmenu-describe-this-bookmark              "bookmark+-bmu")
(declare-function bmkp-bmenu-describe-marked                     "bookmark+-bmu")
(declare-function bmkp-bmenu-change-sort-order-repeat            "bookmark+-bmu")
(declare-function bmkp-reverse-sort-order                        "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-bookmark-name               "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-last-bookmark-access        "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-last-buffer-or-file-access  "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-bookmark-type               "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-file-name                   "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-by-creation-time               "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-annotated-before-unannotated   "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-flagged-before-unflagged       "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-marked-before-unmarked         "bookmark+-bmu")
(declare-function bmkp-save                                      "bookmark+-1")
(declare-function bmkp-load                                      "bookmark+-1")
(declare-function bmkp-switch-bookmark-file-create               "bookmark+-1")
(declare-function bmkp-edit-annotation                           "bookmark+-1")


;;; Sort submenu --------------------------------------------------------

(transient-define-prefix casual-bmkp-sort-tmenu ()
  "Sort the `*Bmkp List*' buffer."
  ["Sort by"
   ("n" "Name"                bmkp-bmenu-sort-by-bookmark-name        :transient nil)
   ("d" "Last bookmark access" bmkp-bmenu-sort-by-last-bookmark-access :transient nil)
   ("b" "Last buffer/file access" bmkp-bmenu-sort-by-last-buffer-or-file-access :transient nil)
   ("k" "Bookmark type"       bmkp-bmenu-sort-by-bookmark-type        :transient nil)
   ("f" "File name"           bmkp-bmenu-sort-by-file-name            :transient nil)
   ("0" "Creation time"       bmkp-bmenu-sort-by-creation-time        :transient nil)]
  ["Group"
   ("a" "Annotated first"     bmkp-bmenu-sort-annotated-before-unannotated :transient nil)
   ("D" "Flagged-D first"     bmkp-bmenu-sort-flagged-before-unflagged :transient nil)
   (">" "Marked first"        bmkp-bmenu-sort-marked-before-unmarked  :transient nil)]
  ["Misc"
   ("r" "Reverse current order" bmkp-reverse-sort-order               :transient nil)
   ("s" "Cycle sort orders"   bmkp-bmenu-change-sort-order-repeat     :transient t)
   ("q" "Back"                transient-quit-one)])


;;; Main menu -----------------------------------------------------------

;;;###autoload (autoload 'casual-bmkp-tmenu "casual-bmkp" nil t)
(transient-define-prefix casual-bmkp-tmenu ()
  "Casual menu for the `*Bmkp List*' buffer."
  [["Move"
    ("n"   "Next line"          next-line                             :transient t)
    ("p"   "Prev line"          previous-line                         :transient t)
    ("RET" "Open here"          bmkp-list-this-window                 :transient nil)
    ("o"   "Open other window"  bmkp-list-other-window                :transient nil)
    ("O"   "Switch other window" bmkp-list-switch-other-window        :transient nil)]
   ["Mark"
    ("m"   "Mark"               bmkp-list-mark                        :transient t)
    ("u"   "Unmark"             bmkp-list-unmark                      :transient t)
    ("t"   "Toggle marks"       bmkp-bmenu-toggle-marks               :transient t)
    ("M"   "Mark all"           bmkp-bmenu-mark-all                   :transient t)
    ("U"   "Unmark all"         bmkp-bmenu-unmark-all                 :transient t)
    ("%"   "Mark by regexp"     bmkp-bmenu-regexp-mark                :transient nil)]
   ["Delete"
    ("d"   "Flag for delete"    bmkp-bmenu-flag-for-deletion          :transient t)
    ("x"   "Execute D flags"    bmkp-list-execute-deletions           :transient nil)
    ("D"   "Delete marked"      bmkp-bmenu-delete-marked              :transient nil)]]

  [["Filter / Show"
    ("."   "Show all"           bmkp-bmenu-show-all                   :transient nil)
    (">"   "Only marked"        bmkp-bmenu-toggle-show-only-marked    :transient nil)
    ("<"   "Only unmarked"      bmkp-bmenu-toggle-show-only-unmarked  :transient nil)
    ("M-t" "Toggle file column" bmkp-list-toggle-filenames            :transient nil)]
   ["Edit"
    ("e"   "Edit record"        bmkp-bmenu-edit-bookmark-record       :transient nil)
    ("E"   "Edit marked"        bmkp-bmenu-edit-marked                :transient nil)
    ("r"   "Rename"             bmkp-list-rename                      :transient nil)
    ("a"   "Show annotation"    bmkp-list-show-annotation             :transient nil)
    ("A"   "Edit annotation"    bmkp-edit-annotation                  :transient nil)]
   ["Files"
    ("S"   "Save"               bmkp-save                             :transient nil)
    ("L"   "Switch bmk file"    bmkp-switch-bookmark-file-create      :transient nil)
    ("l"   "Load"               bmkp-load                             :transient nil)]]

  [["Preview"
    ("P"   "Toggle live preview" bmkp-list-preview-mode               :transient nil)]
   ["Help"
    ("H"   "Describe this"      bmkp-bmenu-describe-this-bookmark     :transient nil)
    ("M-H" "Describe marked"    bmkp-bmenu-describe-marked            :transient nil)]
   ["Sort"
    ("s"   "Sort menu..."       casual-bmkp-sort-tmenu                :transient nil)]
   ["Quit"
    ("g"   "Refresh"            bmkp-bmenu-refresh-menu-list          :transient t)
    ("q"   "Quit list"          bmkp-bmenu-quit                       :transient nil)
    ("C-g" "Close menu"         transient-quit-one)]])


;;; Bind into `bmkp-list-mode-map' when that map is defined ------------

(with-eval-after-load 'bookmark+-bmu
  (when (boundp 'bmkp-list-mode-map)
    (define-key bmkp-list-mode-map "c" #'casual-bmkp-tmenu)))


(provide 'casual-bmkp)

;;; casual-bmkp.el ends here
