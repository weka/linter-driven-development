A function that builds and returns an API type is that type's constructor, not a
helper. It stays beside the type in the feature package. It is public, so its tests
call it directly. A juicy constructor is never {{.Unexported}}.
