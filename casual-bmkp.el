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
(declare-function bmkp-bmenu-edit-bookmark-name-and-location     "bookmark+-bmu")
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
(declare-function bmkp-add-tags                                  "bookmark+-1")
(declare-function bmkp-remove-tags                               "bookmark+-1")
(declare-function bmkp-remove-all-tags                           "bookmark+-1")
(declare-function bmkp-set-tag-value                             "bookmark+-1")
(declare-function bmkp-rename-tag                                "bookmark+-1")
(declare-function bmkp-list-all-tags                             "bookmark+-1")
(declare-function bmkp-bmenu-add-tags-to-marked                  "bookmark+-bmu")
(declare-function bmkp-bmenu-remove-tags-from-marked             "bookmark+-bmu")
(declare-function bmkp-bmenu-list-tags-of-marked                 "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-all           "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-some          "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-regexp        "bookmark+-bmu")
(declare-function bmkp-bmenu-show-only-tagged-bookmarks          "bookmark+-bmu")
(declare-function bmkp-bmenu-show-only-untagged-bookmarks        "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-tagged-before-untagged         "bookmark+-bmu")


;;; Tags submenu --------------------------------------------------------

(transient-define-prefix casual-bmkp-tags-tmenu ()
  "Tag commands for the bookmark on this line, or for marked bookmarks."
  [["This bookmark"
    ("+" "Add tags"            bmkp-add-tags                            :transient nil)
    ("-" "Remove tags"         bmkp-remove-tags                         :transient nil)
    ("0" "Remove all tags"     bmkp-remove-all-tags                     :transient nil)
    ("e" "Edit tags"           bmkp-bmenu-edit-tags                     :transient nil)
    ("v" "Set tag value"       bmkp-set-tag-value                       :transient nil)]
   ["Marked"
    ("M-+" "Add tags"          bmkp-bmenu-add-tags-to-marked            :transient nil)
    ("M--" "Remove tags"       bmkp-bmenu-remove-tags-from-marked       :transient nil)
    ("M-l" "List union of tags" bmkp-bmenu-list-tags-of-marked          :transient nil)]
   ["Mark by tag"
    ("m*"  "All given tags"    bmkp-bmenu-mark-bookmarks-tagged-all     :transient nil)
    ("m+"  "Some given tags"   bmkp-bmenu-mark-bookmarks-tagged-some    :transient nil)
    ("m%"  "Tag matches regex" bmkp-bmenu-mark-bookmarks-tagged-regexp  :transient nil)]]

  [["Show / sort"
    ("S" "Only tagged"         bmkp-bmenu-show-only-tagged-bookmarks    :transient nil)
    ("U" "Only untagged"       bmkp-bmenu-show-only-untagged-bookmarks  :transient nil)
    ("." "Show all"            bmkp-bmenu-show-all                      :transient nil)
    ("s" "Sort: tagged first"  bmkp-bmenu-sort-tagged-before-untagged   :transient nil)]
   ["Global"
    ("l" "List all tags"       bmkp-list-all-tags                       :transient nil)
    ("r" "Rename tag"          bmkp-rename-tag                          :transient nil)]
   ["Quit"
    ("q" "Back"                transient-quit-one)]])


;;; Type-filter submenu ------------------------------------------------

(transient-define-prefix casual-bmkp-type-filter-tmenu ()
  "Show only bookmarks of one type in `*Bmkp List*'."
  [["Locations"
    ("f" "File / directory"     bmkp-bmenu-show-only-file-bookmarks      :transient nil)
    ("r" "Region"               bmkp-bmenu-show-only-region-bookmarks    :transient nil)
    ("a" "Autofile"             bmkp-bmenu-show-only-autofile-bookmarks  :transient nil)
    ("b" "Non-file buffer"      bmkp-bmenu-show-only-non-file-bookmarks  :transient nil)
    ("#" "Autonamed"            bmkp-bmenu-show-only-autonamed-bookmarks :transient nil)]
   ["Apps"
    ("i" "Info node"            bmkp-bmenu-show-only-info-bookmarks      :transient nil)
    ("d" "Dired"                bmkp-bmenu-show-only-dired-bookmarks     :transient nil)
    ("e" "EWW page"             bmkp-bmenu-show-only-eww-bookmarks       :transient nil)
    ("g" "Gnus article"         bmkp-bmenu-show-only-gnus-bookmarks      :transient nil)
    ("m" "man / woman page"     bmkp-bmenu-show-only-man-bookmarks       :transient nil)
    ("I" "Image"                bmkp-bmenu-show-only-image-bookmarks     :transient nil)]
   ["Other"
    ("k" "Desktop"              bmkp-bmenu-show-only-desktop-bookmarks   :transient nil)
    ("y" "Bookmark-file"        bmkp-bmenu-show-only-bookmark-file-bookmarks :transient nil)
    ("z" "Bookmark-list view"   bmkp-bmenu-show-only-bookmark-list-bookmarks :transient nil)
    ("v" "Variable list"        bmkp-bmenu-show-only-variable-list-bookmarks :transient nil)
    ("Q" "Function"             bmkp-bmenu-show-only-function-bookmarks  :transient nil)
    ("w" "Snippet"              bmkp-bmenu-show-only-snippet-bookmarks   :transient nil)
    ("u" "URL"                  bmkp-bmenu-show-only-url-bookmarks       :transient nil)]]

  [["Status"
    ("X" "Temporary"            bmkp-bmenu-show-only-temporary-bookmarks :transient nil)
    ("-" "Omitted"              bmkp-bmenu-show-only-omitted-bookmarks   :transient nil)]
   ["All"
    ("." "Show all"             bmkp-bmenu-show-all                      :transient nil)
    ("q" "Back"                 transient-quit-one)]])


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
    ("r"   "Rename"             bmkp-bmenu-edit-bookmark-name-and-location :transient nil)
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
   ["Tags"
    ("T"   "Tag menu..."        casual-bmkp-tags-tmenu                :transient nil)]
   ["Type"
    ("f"   "Type filter..."     casual-bmkp-type-filter-tmenu         :transient nil)]
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
