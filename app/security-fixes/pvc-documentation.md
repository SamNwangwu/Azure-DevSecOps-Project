# PVC Storage Limits

In response to the SonarQube security findings about missing storage limits on PVCs, we've documented the resolution strategy:

## Limitation

PersistentVolumeClaims have several immutable fields after creation, including:
- accessModes
- storageClassName
- volumeName

This means we cannot directly add storage limits to existing PVCs.

## Resolution Strategy for Production

For production environments, we would:

1. Create a new StorageClass with appropriate quotas and limits
2. Create new PVCs using this StorageClass with explicit storage limits
3. Backup data from the existing volumes
4. Migrate to the new PVCs
5. Delete the old PVCs

## Implementation Notes

For our Azure Kubernetes Service (AKS) deployment, we would:

1. Configure Azure Policy for Kubernetes to enforce resource limits
2. Set up Storage Quotas at the namespace level
3. Implement monitoring and alerting for storage consumption

This approach ensures proper resource governance while respecting Kubernetes' immutability constraints.
