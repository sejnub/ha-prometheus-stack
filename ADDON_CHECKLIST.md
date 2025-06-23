# Home Assistant Add-on Repository Checklist

## ✅ Repository Structure Issues
- [ ] **Add-on files must be in a subfolder** (not in root)
  - Move `config.json`, `Dockerfile`, `run.sh` etc. into a subfolder (e.g., `addon-name/`)
  - Root should only contain: `repository.yaml`, `README.md`, `.github/`, etc.

- [ ] **Repository metadata file required**
  - Create `repository.yaml` in root (NOT `repository.json`)
  - Must contain: `name`, `url`, `maintainer`

## ✅ Config.json Requirements
- [ ] **Slug must match folder name exactly**
  - If folder is `prometheus-stack`, slug must be `"prometheus-stack"`
  - No underscores vs hyphens mismatch

- [ ] **Build configuration required for custom Dockerfile**
  - Add `"build": { "dockerfile": "Dockerfile", "args": [] }`
  - Required when not using pre-built `"image"`

- [ ] **Required fields present**
  - `name`, `version`, `slug`, `description`
  - `arch`, `startup`, `boot`
  - `options` and `schema` for configuration

## ✅ File Structure Validation
- [ ] **No Windows Zone.Identifier files tracked by git**
  - Remove any `*:Zone.Identifier` files
  - Add to `.gitignore` if needed

- [ ] **All required add-on files present**
  - `config.json`
  - `Dockerfile`
  - `run.sh` (executable)
  - Configuration files referenced in Dockerfile

## ✅ Testing & Development Setup
- [ ] **Test scripts updated for new folder structure**
  - Update `test/build-test.sh` to use correct paths
  - Update GitHub Actions workflow context

- [ ] **Both modes work: Add-on mode and Test mode**
  - Add-on mode: reads from `/data/options.json`
  - Test mode: reads from `/data/.env`
  - Priority: options.json > .env > defaults

## ✅ Documentation Updates
- [ ] **README.md reflects new structure**
  - Update file structure diagram
  - Update installation instructions

## 🔍 Final Validation Checklist
- [ ] Repository can be added to Home Assistant Add-on Store
- [ ] Add-on installs without errors
- [ ] Configuration tab works in Home Assistant UI
- [ ] All services start correctly
- [ ] Health checks pass
- [ ] Both development and production modes work

## 📝 Common Mistakes to Avoid
- ❌ Don't put add-on files in repository root
- ❌ Don't use `repository.json` (use `repository.yaml`)
- ❌ Don't mismatch slug and folder name
- ❌ Don't forget `build` configuration for custom Dockerfile
- ❌ Don't leave Windows Zone.Identifier files in git
- ❌ Don't forget to update test scripts for new structure

---

**Next time you build an add-on, use this checklist to avoid these common pitfalls!** 