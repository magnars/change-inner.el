;;; change-inner.el --- Change contents based on semantic units

;; Copyright (C) 2012 Magnar Sveen <magnars@gmail.com>

;; Author: Magnar Sveen <magnars@gmail.com>
;; Keywords: convenience, extensions

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; # change-inner.el
;;
;; change-inner gives you vim's `ci` command, building on
;; [expand-region](https://github.com/magnars/expand-region.el). It is most easily
;; explained by example:
;;
;;     function test() {
;;       return "semantic kill";
;;     }
;;
;; With point after the word `semantic`
;;
;;  * `change-inner "` would kill the contents of the string
;;  * `change-outer "` would kill the entire string
;;  * `change-inner {` would kill the return-statement
;;  * `change-outer {` would kill the entire block
;;
;; I use `M-i` and `M-o` for this.
;;
;; Giving these commands a prefix argument `C-u` means copy instead of kill.
;;
;; ## Installation
;;
;; Start by installing
;; [expand-region](https://github.com/magnars/expand-region.el).
;;
;;     (require 'change-inner)
;;     (global-set-key (kbd "M-i") 'change-inner)
;;     (global-set-key (kbd "M-o") 'change-outer)
;;
;; ## It's not working in my favorite mode
;;
;; That may just be because expand-region needs some love for your mode. Please
;; open a ticket there: https://github.com/magnars/expand-region.el

;;; Code:

(require 'expand-region)

(defun ci--flash-region (start end)
  "Temporarily highlight region from START to END."
  (let ((overlay (make-overlay start end)))
    (overlay-put overlay 'face 'secondary-selection)
    (overlay-put overlay 'priority 100)
    (run-with-timer 0.2 nil 'delete-overlay overlay)))

(defun change-inner (arg)
  "Works like vim's ci command. Takes a char, like ( or \" and
kills the innards of the first ancestor semantic unit starting with that char."
  (interactive "p")
  (let ((char (char-to-string
               (read-char
                (if (= 1 arg)
                    "Change inner, starting with:"
                  "Yank inner, starting with:")))))
    (flet ((message (&rest args) nil))
      (when (looking-at char)
        (forward-char 1))
      (save-excursion
        (er/expand-region 1)
        (while (not (looking-at char))
          (er/expand-region 1)
          (when (and (= (point) (point-min))
                     (not (looking-at char)))
            (error "Couldn't find any expansion starting with %S" char)))
        (er/contract-region 1)
        (if (= 1 arg)
            (kill-region (region-beginning) (region-end))
          (copy-region-as-kill (region-beginning) (region-end))
          (ci--flash-region (region-beginning) (region-end)))))))

(defun change-outer (arg)
  "Works like vim's ci command. Takes a char, like ( or \" and
kills the first ancestor semantic unit starting with that char."
  (interactive "p")
  (let ((char (char-to-string
               (read-char
                (if (= 1 arg)
                    "Change outer, starting with:"
                  "Yank outer, starting with:")))))
    (flet ((message (&rest args) nil))
      (save-excursion
        (when (looking-at char)
          (er/expand-region 1))
        (while (not (looking-at char))
          (er/expand-region 1)
          (when (and (= (point) (point-min))
                     (not (looking-at char)))
            (error "Couldn't find any expansion starting with %S" char)))
        (if (= 1 arg)
            (kill-region (region-beginning) (region-end))
          (copy-region-as-kill (region-beginning) (region-end))
          (ci--flash-region (region-beginning) (region-end)))))))

(provide 'change-inner)
;;; change-inner.el ends here
