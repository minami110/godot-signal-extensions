# GDScript File Manager - Examples

## Basic Operations

### Move
```bash
mv dev/foo/folder1/script.gd dev/foo/folder2/script.gd && \
mv dev/foo/folder1/script.gd.uid dev/foo/folder2/script.gd.uid
```

### Rename
```bash
mv scripts/old_name.gd scripts/new_name.gd && \
mv scripts/old_name.gd.uid scripts/new_name.gd.uid
```

### Delete
```bash
rm scripts/unused.gd && rm scripts/unused.gd.uid
```

## Advanced Use Cases

### Multiple Files
Move all GDScript files from one directory to another:

```bash
for file in components/*.gd; do
    filename=$(basename "$file")
    mv "components/$filename" "systems/$filename" && \
    mv "components/$filename.uid" "systems/$filename.uid"
done
```

### Deep Paths with New Directory
```bash
# Create destination if needed
mkdir -p addons/plugin/systems

# Move files
mv addons/plugin/core/manager.gd addons/plugin/systems/manager.gd && \
mv addons/plugin/core/manager.gd.uid addons/plugin/systems/manager.gd.uid
```
