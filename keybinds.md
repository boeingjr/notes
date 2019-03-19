~~~
C-x C-s   save
C-s       find
M-s       find class
C-f       fw
C-b       bw -o-
M-f       fw-word
M-b       bw-word
C-p       up -o-
C-n       down
M-p       up-block
M-n       down-block
C-x p   beginning of buffer (Scroll to top)   ---
C-x n   end of buffer
~~~

~~~
C-w       cut
M-w       copy
C-y       paste -o-

C-a     beginning of line               cut           -> C-w
C-e     end of line                     -o-
C-x l   center screen here             ---
C-w     cut                            extend selection


C-d     delete                         -o-
M-d     delete-word-fw                 -o-

M-Backspace delete-word-bw
C-k     delete line                    -o-  

C-s     find
C-l     find-next (cannot use incremental-search)
C-S-l   find-previous                  ---
C-R     replace                        as is


C--     undo                           
C-S--   redo
~~~

available:

C-i  (implement methods)
C-u  (goto super)
C-h
C-g goto?
C-v paste - moved to C-y
C-x cut - moved to C-w
C-c copy - moved to M-w
C-t (somethin somethin)
