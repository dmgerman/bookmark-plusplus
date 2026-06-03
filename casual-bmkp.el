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
;; filter/show, sort, edit, files, preview, help.  Sort, Tags, and
;; Type-filter live in their own submenus.
;;
;; The menu is persistent: every command keeps the menu open.  Users
;; dismiss it explicitly with `q' (one level up) or `Q' (close all).
;; The exception is `X' in the main menu, which kills *Bmkp List*
;; itself -- the menu has nothing to overlay afterward.

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
(declare-function bmkp-bmenu-cycle-filename-style                "bookmark+-bmu")
(declare-function bmkp-bmenu-set-filename-style                  "bookmark+-bmu")
(declare-function bmkp-bmenu-toggle-tags-column                  "bookmark+-bmu")
(declare-function bmkp-bmenu-set-tags-column-width               "bookmark+-bmu")
(declare-function bmkp-bmenu-set-name-column-width               "bookmark+-bmu")
(defvar bmkp-bmenu-filename-style)
(defvar bmkp-bmenu-show-tags-flag)
(defvar bmkp-bmenu-tags-column-width)
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
(declare-function bmkp-bmenu-edit-annotation                     "bookmark+-bmu")
(declare-function bmkp-rename-tag                                "bookmark+-1")
(declare-function bmkp-list-all-tags                             "bookmark+-1")
(declare-function bmkp-bmenu-add-tags                            "bookmark+-bmu")
(declare-function bmkp-bmenu-remove-tags                         "bookmark+-bmu")
(declare-function bmkp-bmenu-remove-all-tags                     "bookmark+-bmu")
(declare-function bmkp-bmenu-set-tag-value                       "bookmark+-bmu")
(declare-function bmkp-bmenu-add-tags-to-marked                  "bookmark+-bmu")
(declare-function bmkp-bmenu-remove-tags-from-marked             "bookmark+-bmu")
(declare-function bmkp-bmenu-list-tags-of-marked                 "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-all           "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-some          "bookmark+-bmu")
(declare-function bmkp-bmenu-mark-bookmarks-tagged-regexp        "bookmark+-bmu")
(declare-function bmkp-bmenu-show-only-tagged-bookmarks          "bookmark+-bmu")
(declare-function bmkp-bmenu-show-only-untagged-bookmarks        "bookmark+-bmu")
(declare-function bmkp-bmenu-sort-tagged-before-untagged         "bookmark+-bmu")


;; Every command in the submenus uses `:transient t' so the menu
;; stays open after each invocation -- it only closes on explicit
;; `q' (one level up) or `Q' (quit all).  Submenu openers in the
;; main menu use the same default; transient walks back to the
;; parent prefix on `transient-quit-one'.

;;; Tags submenu --------------------------------------------------------

(transient-define-prefix casual-bmkp-tags-tmenu ()
  "Tag commands for the bookmark on this line, or for marked bookmarks."
  [["This bookmark"
    ("+" "Add tags"            bmkp-bmenu-add-tags                      :transient t)
    ("-" "Remove tags"         bmkp-bmenu-remove-tags                   :transient t)
    ("0" "Remove all tags"     bmkp-bmenu-remove-all-tags               :transient t)
    ("e" "Edit tags"           bmkp-bmenu-edit-tags                     :transient t)
    ("v" "Set tag value"       bmkp-bmenu-set-tag-value                 :transient t)]
   ["Marked"
    ("M-+" "Add tags"          bmkp-bmenu-add-tags-to-marked            :transient t)
    ("M--" "Remove tags"       bmkp-bmenu-remove-tags-from-marked       :transient t)
    ("M-l" "List union of tags" bmkp-bmenu-list-tags-of-marked          :transient t)]
   ["Mark by tag"
    ("m*"  "All given tags"    bmkp-bmenu-mark-bookmarks-tagged-all     :transient t)
    ("m+"  "Some given tags"   bmkp-bmenu-mark-bookmarks-tagged-some    :transient t)
    ("m%"  "Tag matches regex" bmkp-bmenu-mark-bookmarks-tagged-regexp  :transient t)]]

  [["Show / sort"
    ("S" "Only tagged"         bmkp-bmenu-show-only-tagged-bookmarks    :transient t)
    ("U" "Only untagged"       bmkp-bmenu-show-only-untagged-bookmarks  :transient t)
    ("." "Show all"            bmkp-bmenu-show-all                      :transient t)
    ("s" "Sort: tagged first"  bmkp-bmenu-sort-tagged-before-untagged   :transient t)]
   ["Display"
    ("M-T" "Tags column..."    bmkp-bmenu-toggle-tags-column
     :description casual-bmkp--tags-column-label                        :transient t)
    ("w"   "Set tags width"    bmkp-bmenu-set-tags-column-width         :transient t)
    ("W"   "Set name width"    bmkp-bmenu-set-name-column-width         :transient t)]
   ["Global"
    ("l" "List all tags"       bmkp-list-all-tags                       :transient t)
    ("r" "Rename tag"          bmkp-rename-tag                          :transient t)]
   ["Exit"
    ("q" "Back"                transient-quit-one)
    ("Q" "Quit menu"           transient-quit-all)]])


;;; Type-filter submenu ------------------------------------------------

(transient-define-prefix casual-bmkp-type-filter-tmenu ()
  "Show only bookmarks of one type in `*Bmkp List*'."
  [["Locations"
    ("f" "File / directory"     bmkp-bmenu-show-only-file-bookmarks      :transient t)
    ("r" "Region"               bmkp-bmenu-show-only-region-bookmarks    :transient t)
    ("a" "Autofile"             bmkp-bmenu-show-only-autofile-bookmarks  :transient t)
    ("b" "Non-file buffer"      bmkp-bmenu-show-only-non-file-bookmarks  :transient t)
    ("#" "Autonamed"            bmkp-bmenu-show-only-autonamed-bookmarks :transient t)]
   ["Apps"
    ("i" "Info node"            bmkp-bmenu-show-only-info-bookmarks      :transient t)
    ("d" "Dired"                bmkp-bmenu-show-only-dired-bookmarks     :transient t)
    ("e" "EWW page"             bmkp-bmenu-show-only-eww-bookmarks       :transient t)
    ("g" "Gnus article"         bmkp-bmenu-show-only-gnus-bookmarks      :transient t)
    ("m" "man / woman page"     bmkp-bmenu-show-only-man-bookmarks       :transient t)
    ("I" "Image"                bmkp-bmenu-show-only-image-bookmarks     :transient t)]
   ["Other"
    ("k" "Desktop"              bmkp-bmenu-show-only-desktop-bookmarks   :transient t)
    ("y" "Bookmark-file"        bmkp-bmenu-show-only-bookmark-file-bookmarks :transient t)
    ("z" "Bookmark-list view"   bmkp-bmenu-show-only-bookmark-list-bookmarks :transient t)
    ("v" "Variable list"        bmkp-bmenu-show-only-variable-list-bookmarks :transient t)
    ("F" "Function"             bmkp-bmenu-show-only-function-bookmarks  :transient t)
    ("w" "Snippet"              bmkp-bmenu-show-only-snippet-bookmarks   :transient t)
    ("u" "URL"                  bmkp-bmenu-show-only-url-bookmarks       :transient t)]]

  [["Status"
    ("X" "Temporary"            bmkp-bmenu-show-only-temporary-bookmarks :transient t)
    ("-" "Omitted"              bmkp-bmenu-show-only-omitted-bookmarks   :transient t)]
   ["All"
    ("." "Show all"             bmkp-bmenu-show-all                      :transient t)]
   ["Exit"
    ("q" "Back"                 transient-quit-one)
    ("Q" "Quit menu"            transient-quit-all)]])


;;; Sort submenu --------------------------------------------------------

(transient-define-prefix casual-bmkp-sort-tmenu ()
  "Sort the `*Bmkp List*' buffer."
  [["Sort by"
    ("n" "Name"                bmkp-bmenu-sort-by-bookmark-name        :transient t)
    ("d" "Last bookmark access" bmkp-bmenu-sort-by-last-bookmark-access :transient t)
    ("b" "Last buffer/file access" bmkp-bmenu-sort-by-last-buffer-or-file-access :transient t)
    ("k" "Bookmark type"       bmkp-bmenu-sort-by-bookmark-type        :transient t)
    ("f" "File name"           bmkp-bmenu-sort-by-file-name            :transient t)
    ("0" "Creation time"       bmkp-bmenu-sort-by-creation-time        :transient t)]
   ["Group"
    ("a" "Annotated first"     bmkp-bmenu-sort-annotated-before-unannotated :transient t)
    ("D" "Flagged-D first"     bmkp-bmenu-sort-flagged-before-unflagged :transient t)
    (">" "Marked first"        bmkp-bmenu-sort-marked-before-unmarked  :transient t)]
   ["Misc"
    ("r" "Reverse current order" bmkp-reverse-sort-order               :transient t)
    ("s" "Cycle sort orders"   bmkp-bmenu-change-sort-order-repeat     :transient t)]
   ["Exit"
    ("q" "Back"                transient-quit-one)
    ("Q" "Quit menu"           transient-quit-all)]])


(defun casual-bmkp--filename-style-label ()
  "Transient description for the filename-style cycle entry.
Shows the current value of `bmkp-bmenu-filename-style' inline."
  (format "Filename style: %s"
          (if (boundp 'bmkp-bmenu-filename-style)
              bmkp-bmenu-filename-style
            'abbreviate)))

(defun casual-bmkp--tags-column-label ()
  "Transient description for the tags-column toggle entry.
Shows whether the tags column is on and at what width."
  (if (and (boundp 'bmkp-bmenu-show-tags-flag) bmkp-bmenu-show-tags-flag)
      (format "Tags column: on (%d chars)"
              (if (boundp 'bmkp-bmenu-tags-column-width)
                  bmkp-bmenu-tags-column-width
                18))
    "Tags column: off"))


;;; Main menu -----------------------------------------------------------

;;;###autoload (autoload 'casual-bmkp-tmenu "casual-bmkp" nil t)
(transient-define-prefix casual-bmkp-tmenu ()
  "Casual menu for the `*Bmkp List*' buffer.

The menu persists between commands.  Press \\`Q' to dismiss it
explicitly, \\`X' to kill the `*Bmkp List*' buffer."
  [["Move"
    ("n"   "Next line"          next-line                             :transient t)
    ("p"   "Prev line"          previous-line                         :transient t)
    ("RET" "Open here"          bmkp-list-this-window                 :transient t)
    ("o"   "Open other window"  bmkp-list-other-window                :transient t)
    ("O"   "Switch other window" bmkp-list-switch-other-window        :transient t)]
   ["Mark"
    ("m"   "Mark"               bmkp-list-mark                        :transient t)
    ("u"   "Unmark"             bmkp-list-unmark                      :transient t)
    ("t"   "Toggle marks"       bmkp-bmenu-toggle-marks               :transient t)
    ("M"   "Mark all"           bmkp-bmenu-mark-all                   :transient t)
    ("U"   "Unmark all"         bmkp-bmenu-unmark-all                 :transient t)
    ("%"   "Mark by regexp"     bmkp-bmenu-regexp-mark                :transient t)]
   ["Delete"
    ("d"   "Flag for delete"    bmkp-bmenu-flag-for-deletion          :transient t)
    ("x"   "Execute D flags"    bmkp-list-execute-deletions           :transient t)
    ("D"   "Delete marked"      bmkp-bmenu-delete-marked              :transient t)]]

  [["Filter / Show"
    ("."   "Show all"           bmkp-bmenu-show-all                   :transient t)
    (">"   "Only marked"        bmkp-bmenu-toggle-show-only-marked    :transient t)
    ("<"   "Only unmarked"      bmkp-bmenu-toggle-show-only-unmarked  :transient t)
    ("M-t" "Toggle file column" bmkp-list-toggle-filenames            :transient t)
    ("M-F" "Filename style..."  bmkp-bmenu-cycle-filename-style
     :description casual-bmkp--filename-style-label                    :transient t)]
   ["Edit"
    ("e"   "Edit record"        bmkp-bmenu-edit-bookmark-record       :transient t)
    ("E"   "Edit marked"        bmkp-bmenu-edit-marked                :transient t)
    ("r"   "Rename"             bmkp-bmenu-edit-bookmark-name-and-location :transient t)
    ("a"   "Show annotation"    bmkp-list-show-annotation             :transient t)
    ;; Edit pops up an annotation-compose buffer for the user to work
    ;; in; close the menu so they can edit without it overlaying.
    ("A"   "Edit annotation"    bmkp-bmenu-edit-annotation            :transient nil)]
   ["Files"
    ("S"   "Save"               bmkp-save                             :transient t)
    ("L"   "Switch bmk file"    bmkp-switch-bookmark-file-create      :transient t)
    ("l"   "Load"               bmkp-load                             :transient t)]]

  [["Preview"
    ("P"   "Toggle live preview" bmkp-list-preview-mode               :transient t)]
   ["Help"
    ("H"   "Describe this"      bmkp-bmenu-describe-this-bookmark     :transient t)
    ("M-H" "Describe marked"    bmkp-bmenu-describe-marked            :transient t)]
   ["Submenus"
    ("s"   "Sort menu..."       casual-bmkp-sort-tmenu                :transient t)
    ("T"   "Tag menu..."        casual-bmkp-tags-tmenu                :transient t)
    ("f"   "Type filter..."     casual-bmkp-type-filter-tmenu         :transient t)]
   ["Exit"
    ("g"   "Refresh"            bmkp-bmenu-refresh-menu-list          :transient t)
    ("X"   "Kill *Bmkp List*"   bmkp-bmenu-quit                       :transient nil)
    ("Q"   "Quit menu"          transient-quit-all)]])


;;; Bind into `bmkp-list-mode-map' when that map is defined ------------

(with-eval-after-load 'bookmark+-bmu
  (when (boundp 'bmkp-list-mode-map)
    (define-key bmkp-list-mode-map "c" #'casual-bmkp-tmenu)))


(provide 'casual-bmkp)

;;; casual-bmkp.el ends here
