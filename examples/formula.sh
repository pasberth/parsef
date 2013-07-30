cd "`dirname $0`"

export PATH="../bin:$PATH"
export FORMULAV="α β γ"

expr ()                          \
  { echo "$@"                    \
  | split-on-spaces              \
  | punctuation-mark '(' ')' '¬' \
  | between '(' ')'              \
      eval 'foldr -@¬ formula "(¬ α)" ¬ α | formula "(∧ α β)" α ∧ β | formula "(∨ α β)" α ∨ β | foldr -@→ formula "(→ α β)" α → β ' \
  | foldr -@¬ formula "(¬ α)" ¬ α \
  | formula "(∧ α β)" α ∧ β \
  | formula "(∨ α β)" α ∨ β \
  | foldr -@→ formula "(→ α β)" α → β
  }

expr "(β → γ) → (α → β) → α → γ"
expr "(α → β → γ) → β → α → γ"
expr "α → β → α"
expr "(α → α → β) → α → β"
expr "⊥ → α"
expr "(α → β) → (α → γ) → α → β ∧ γ"
expr "α ∧ β → α"
expr "α ∧ β → β"
expr "α → α ∨ β"
expr "β → α ∨ β"
expr "(α → γ) → (β → γ) → α ∨ β → γ"

# => (→ (→ β γ) (→ (→ α β) (→ α γ)))
# => (→ (→ α (→ β γ)) (→ β (→ α γ)))
# => (→ α (→ β α))
# => (→ (→ α (→ α β)) (→ α β))
# => (→ ⊥ α)
# => (→ (→ α β) (→ (→ α γ) (→ α (∧ β γ))))
# => (→ (∧ α β) α)
# => (→ (∧ α β) β)
# => (→ α (∨ α β))
# => (→ β (∨ α β))
# => (→ (→ α γ) (→ (→ β γ) (→ (∨ α β) γ)))
