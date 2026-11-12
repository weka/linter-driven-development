When a nested package builds that type, the nested package defines it. The feature
package re-exports it with a type alias (`type Verdict = classify.Verdict`) and its
constants. The feature package cannot define it: the nested package would import its
parent, and Go rejects that import cycle.
