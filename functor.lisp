(in-package #:vivace-graph-v2)

(defstruct (functor
	     (:constructor %make-functor)
	     (:predicate functor?))
  name fn clauses (lock (make-recursive-lock)))

(defun lookup-functor (name)
  (gethash name *user-functors*))

(defun make-functor (&key name clauses)
  (or (lookup-functor name)
      (let ((functor (%make-functor :name name
				    :clauses clauses)))
	(prog1
	    (setf (gethash name *user-functors*) functor)
	  (prolog-compile functor)))))

(defun add-functor-clause (functor clause)
  (with-recursive-lock-held ((functor-lock functor))
    (cas (cdr (last (functor-clauses functor)))
	 (cdr (last (functor-clauses functor)))
	 (list clause))
    (prolog-compile functor))
  (functor-clauses functor))

(defun delete-functor (functor)
  (remhash (functor-name functor) *user-functors*))

(defun reset-functor (functor)
  (with-recursive-lock-held ((functor-lock functor))
    (cas (functor-clauses functor) (functor-clauses functor) nil)
    (prolog-compile functor))
  nil)

(defun get-functor-fn (functor-symbol)
  (let ((f (lookup-functor functor-symbol)))
    (when (functor? f)
      (functor-fn f))))

(defun set-functor-fn (functor-symbol fn)
  (let ((f (lookup-functor functor-symbol)))
    ;;(when *prolog-trace* (format t "set-functor-fn for ~A got ~A~%" functor-symbol f))
    (if (functor? f)
	(setf (functor-fn f) fn)
	(error 'prolog-error 
	       :reason (format nil "unknown functor ~A" functor-symbol)))))