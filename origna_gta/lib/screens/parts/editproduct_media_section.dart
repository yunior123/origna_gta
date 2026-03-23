part of '../editproduct_screen.dart';

extension _EditProductMedia on _EditProductScreenState {
  Widget buildMediaSection(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('product.images'.tr()),
        _buildImageGrid(state, viewModel),
        const SizedBox(height: 12),
        ProductAddImages(
          imageModels: state.newImages,
          onImagesChanged: viewModel.updateNewImages,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('product.product_video'.tr()),
        ProductAddVideo(
          videoFile: state.videoFile,
          existingVideoUrl: state.existingVideoUrl,
          onVideoAdded: (file, duration) => viewModel.setVideo(file, duration),
          onVideoRemoved: () => viewModel.removeVideo(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
