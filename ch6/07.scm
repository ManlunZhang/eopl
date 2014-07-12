(load-relative "../libs/init.scm")
(load-relative "./base/let-structures.scm")
(load-relative "./base/let-cases.scm")
(load-relative "./base/test.scm")
(load-relative "./base/lang.scm")

;; value-of-program : Program -> FinalAnswer
(define value-of-program
  (lambda (pgm)
    (cases program pgm
	   (a-program (exp1)
		      (value-of/k exp1 (init-env) (end-cont))))))

;; value-of/k : Exp * Env * Cont -> FinalAnswer
(define value-of/k
  (lambda (exp env cont)
    (cases expression exp
	   (const-exp (num) (apply-cont cont (num-val num)))
	   (var-exp (var) (apply-cont cont (apply-env env var)))
	   (proc-exp (var body)
		     (apply-cont cont
				 (proc-val (procedure var body env))))
	   (letrec-exp (p-name b-var p-body letrec-body)
		       (value-of/k letrec-body
				   (extend-env-rec p-name b-var p-body env)
				   cont))
	   (zero?-exp (exp1)
		      (value-of/k exp1 env
				  (zero1-cont cont)))
	   (let-exp (var exp1 body)
		    (value-of/k exp1 env
				(let-exp-cont var body env cont)))
	   (if-exp (exp1 exp2 exp3)
		   (value-of/k exp1 env
			       (if-test-cont exp2 exp3 env cont)))
	   (diff-exp (exp1 exp2)
		     (value-of/k exp1 env
				 (diff1-cont exp2 env cont)))
	   (call-exp (rator rand)
		     (value-of/k rator env
				 (rator-cont rand env cont)))
	   )))

;; apply-cont : Cont * ExpVal -> FinalAnswer
(define apply-cont
  (lambda (cont val)
    (cases continuation cont
	   (end-cont ()
		     (begin
		       (eopl:printf
			"End of computation.~%")
		       val))
	   (zero1-cont (saved-cont)
		       (apply-cont saved-cont
				   (bool-val
				    (zero? (expval->num val)))))
	   (let-exp-cont (var body saved-env saved-cont)
			 (value-of/k body
				     (extend-env var val saved-env) saved-cont))
	   (if-test-cont (exp2 exp3 saved-env saved-cont)
			 (if (expval->bool val)
			     (value-of/k exp2 saved-env saved-cont)
			     (value-of/k exp3 saved-env saved-cont)))
	   (diff1-cont (exp2 saved-env saved-cont)
		       (value-of/k exp2
				   saved-env (diff2-cont val saved-cont)))
	   (diff2-cont (val1 saved-cont)
		       (let ((num1 (expval->num val1))
			     (num2 (expval->num val)))
			 (apply-cont saved-cont
				     (num-val (- num1 num2)))))
	   (rator-cont (rand saved-env saved-cont)
		       (value-of/k rand saved-env
				   (rand-cont val saved-cont)))
	   (rand-cont (val1 saved-cont)
		      (let ((proc (expval->proc val1)))
			(apply-procedure/k proc val saved-cont)))
	   )))

;; apply-procedure/k : Proc * ExpVal * Cont -> FinalAnswer
(define apply-procedure/k
  (lambda (proc1 arg cont)
    (cases proc proc1
	   (procedure (var body saved-env)
		      (value-of/k body
				  (extend-env var arg saved-env)
				  cont)))))


(run-all)
