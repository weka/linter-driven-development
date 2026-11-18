package gen

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/weka/linter-driven-development/tools/ldd-gen/internal/binding"
	"github.com/weka/linter-driven-development/tools/ldd-gen/internal/check"
	"github.com/weka/linter-driven-development/tools/ldd-gen/internal/profile"
	"github.com/weka/linter-driven-development/tools/ldd-gen/internal/render"
	"github.com/weka/linter-driven-development/tools/ldd-gen/internal/residue"
)

// document is one standalone file a binding renders outside its plugin
// directory: the coding-rules handbook or its digest, at the
// repository-relative path the profile names.
type document struct {
	path string
	data []byte
}

// renderDocuments renders the handbook and the digest the profile names, in
// that order, each through the residue gate.
func renderDocuments(core fs.FS, b binding.Binding) ([]document, error) {
	p := b.Profile()
	sources := []struct {
		path   string
		render func(fs.FS, binding.Binding) ([]byte, error)
	}{
		{path: p.Handbook, render: render.Handbook},
		{path: p.Digest, render: render.Digest},
	}
	var docs []document
	for _, src := range sources {
		if src.path == "" {
			continue
		}
		data, err := src.render(core, b)
		if err != nil {
			return nil, err
		}
		if err := requireNoGoResidue(p, src.path, data); err != nil {
			return nil, err
		}
		docs = append(docs, document{path: src.path, data: data})
	}
	return docs, nil
}

// goLang is the binding whose documents may spell Go: the residue scanner
// names Go idioms, so the Go handbook is the one it cannot judge.
const goLang = "Go"

// requireNoGoResidue fails the rendering of a document for any language other
// than Go that still carries a Go spelling. In the plugin a Principle sits
// beside a same-language example that softens such a sentence; a document
// renders it alone, so a hit is a core sentence that wants a neutral rewrite.
func requireNoGoResidue(p profile.Profile, path string, data []byte) error {
	if p.Lang == goLang {
		return nil
	}
	hits := residue.ScanHandbook(path, string(data))
	if len(hits) == 0 {
		return nil
	}
	var b strings.Builder
	fmt.Fprintf(&b, "%s carries Go residue; reword the core sentence or the binding's include:", path)
	for _, h := range hits {
		fmt.Fprintf(&b, "\n  %s:%d [%s] %s", h.Path, h.Line, h.Token, h.Text)
	}
	return errors.New(b.String())
}

// requireDocumentTargets runs before anything is written: a file already at a
// document's path must itself be generated — it opens with the generator's
// marker — so a hand-written document there is refused while the plugin
// directory is still untouched, never after a partial write.
func (r Repo) requireDocumentTargets(docs []document) error {
	for _, d := range docs {
		existing, err := os.ReadFile(r.documentPath(d.path))
		switch {
		case errors.Is(err, fs.ErrNotExist):
			continue
		case err != nil:
			return fmt.Errorf("generate: %s: %w", d.path, err)
		case !strings.HasPrefix(string(existing), render.HandbookMarker):
			return fmt.Errorf("generate: %s exists and is not a generated handbook or digest; refusing to overwrite it", d.path)
		}
	}
	return nil
}

func (r Repo) documentPath(rel string) string {
	return filepath.Join(r.root, filepath.FromSlash(rel))
}

// writeDocuments writes each rendered document to its path with mode 0644.
// WriteFile keeps an existing file's mode, so the mode is set explicitly: a
// document is never executable.
func (r Repo) writeDocuments(docs []document) error {
	for _, d := range docs {
		target := r.documentPath(d.path)
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return fmt.Errorf("generate: %s: %w", d.path, err)
		}
		if err := os.WriteFile(target, d.data, 0o644); err != nil {
			return fmt.Errorf("generate: %s: %w", d.path, err)
		}
		if err := os.Chmod(target, 0o644); err != nil {
			return fmt.Errorf("generate: %s: %w", d.path, err)
		}
	}
	return nil
}

// claimDocument records one document path of a binding. Two documents at one
// path would overwrite each other, and a path below another document needs
// that file to be a directory, so both are refused.
func claimDocument(docs map[string]string, lang, path string) error {
	if path == "" {
		return nil
	}
	for other, otherLang := range docs {
		if other == path || strings.HasPrefix(path, other+"/") || strings.HasPrefix(other, path+"/") {
			return fmt.Errorf("generate: bindings %s and %s both render %q; %s renders %q", otherLang, lang, other, lang, path)
		}
	}
	docs[path] = lang
	return nil
}

// requireDocumentsOutsidePlugins keeps every document out of every plugin
// directory and out of the generator's own inputs, where check would count it
// as an extra file or generate would read it back as a source.
func requireDocumentsOutsidePlugins(docs, owner map[string]string) error {
	for path, lang := range docs {
		top := strings.SplitN(path, "/", 2)[0]
		if _, plugin := owner[top]; plugin || top == coreDir || top == langDir {
			return fmt.Errorf("generate: %s renders %q, inside a directory the generator owns", lang, path)
		}
	}
	return nil
}

// checkDocuments compares each rendered document with the file at its path,
// reporting a missing or changed document the way plugin files are reported.
func (r Repo) checkDocuments(w io.Writer, lang string, docs []document) (int, error) {
	total := 0
	for _, d := range docs {
		kind, differs, err := documentDifference(r.documentPath(d.path), d.data)
		if err != nil {
			return total, err
		}
		if !differs {
			continue
		}
		fmt.Fprintf(w, "%s: %s differs from its rendering\n", lang, d.path)
		check.Report(w, []check.Difference{{Path: d.path, Kind: kind}}, render.Tree{d.path: {Data: d.data}}, r.root)
		total++
	}
	return total, nil
}

// documentDifference compares a document on disk with its rendering the way
// plugin files are compared: missing, changed bytes, or an executable bit the
// rendering never sets.
func documentDifference(target string, want []byte) (check.Kind, bool, error) {
	onDisk, err := os.ReadFile(target)
	if errors.Is(err, fs.ErrNotExist) {
		return check.Missing, true, nil
	}
	if err != nil {
		return "", false, fmt.Errorf("check: %w", err)
	}
	if !bytes.Equal(onDisk, want) {
		return check.Changed, true, nil
	}
	info, err := os.Stat(target)
	if err != nil {
		return "", false, fmt.Errorf("check: %w", err)
	}
	if info.Mode()&0o111 != 0 {
		return check.ExecChanged, true, nil
	}
	return "", false, nil
}
