# Home Assistant Add-on Checklist

## Directory Structure Requirements

- [x] **Add-on directory**: Must be in a subdirectory (e.g., `influxdb-stack/`)
- [x] **Required files**: `config.json`, `Dockerfile`, `README.md` in add-on directory
- [x] **Repository structure**: Add-on files must be in subdirectory, not root

## Configuration Requirements

- [x] **Slug consistency**: 
  - If folder is `influxdb-stack`, slug must be `"influxdb-stack"`
  - Repository name should match: `ha-influxdb-stack`
- [x] **Version format**: Use semantic versioning (e.g., `"1.0.0"`)
- [x] **Architecture support**: Include supported architectures (`amd64`, `arm64`)

## File Structure

```
repository-root/
├── influxdb-stack/           # Add-on directory
│   ├── config.json          # Required: Add-on configuration
│   ├── Dockerfile           # Required: Container definition
│   ├── README.md            # Required: Add-on documentation
│   └── rootfs/              # Container filesystem
├── README.md                # Repository documentation
└── repository.yaml          # Repository metadata
```

## Testing Requirements

- [x] **Local testing**: Test scripts in `test/` directory
- [x] **Container builds**: Verify Docker image builds successfully
- [x] **Service health**: All services start and respond to health checks
- [x] **Port accessibility**: Required ports are accessible and functional

## Documentation Requirements

- [x] **README.md**: Clear installation and usage instructions
- [x] **Configuration docs**: Document all configuration options
- [x] **Troubleshooting**: Common issues and solutions
- [x] **Version info**: Changelog and version history

## Home Assistant Integration

- [x] **Ingress support**: Web UI accessible through Home Assistant
- [x] **Supervisor API**: Proper integration with Home Assistant Supervisor
- [x] **Add-on store**: Compatible with Home Assistant Add-on Store format
- [x] **Persistent data**: Data survives container restarts

## Security Requirements

- [x] **Non-root execution**: Services run as non-root user where possible
- [x] **Minimal permissions**: Only required permissions in config.json
- [x] **Secure defaults**: Safe default configuration values
- [x] **Input validation**: Proper validation of user inputs

## Quality Assurance

- [x] **Code quality**: Clean, maintainable code structure
- [x] **Error handling**: Proper error messages and recovery
- [x] **Logging**: Appropriate logging levels and messages
- [x] **Performance**: Efficient resource usage

## Release Preparation

- [x] **Version bump**: Update version in config.json
- [x] **Changelog**: Document changes in CHANGELOG.md
- [x] **Testing**: Full test suite passes
- [x] **Documentation**: All docs updated for new version

## Post-Release

- [x] **Monitoring**: Monitor for issues after release
- [x] **User feedback**: Respond to user reports and questions
- [x] **Maintenance**: Regular updates and security patches
- [x] **Community**: Engage with Home Assistant community
