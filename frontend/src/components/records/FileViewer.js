import React, { useState, useEffect } from 'react';
import { Modal, Spin, message } from 'antd';
import { Document, Page, pdfjs } from 'react-pdf';
// 更新CSS文件路径，移除esm目录
import 'react-pdf/dist/Page/AnnotationLayer.css';
import 'react-pdf/dist/Page/TextLayer.css';

// 设置PDF.js worker路径
pdfjs.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjs.version}/pdf.worker.min.js`;

const FileViewer = ({ visible, fileUrl, fileType, fileName, onClose }) => {
  const [loading, setLoading] = useState(true);
  const [numPages, setNumPages] = useState(null);
  const [pageNumber, setPageNumber] = useState(1);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    setLoading(true);
    if (visible) {
      // 重置状态
      setPageNumber(1);
      setScale(1);
    }
  }, [visible, fileUrl]);

  const handleLoadSuccess = ({ numPages }) => {
    setNumPages(numPages);
    setLoading(false);
  };

  const handleLoadError = (error) => {
    console.error('文件加载错误:', error);
    message.error('文件加载失败，请稍后重试');
    setLoading(false);
  };

  const handleZoomIn = () => {
    setScale(scale + 0.2);
  };

  const handleZoomOut = () => {
    if (scale > 0.4) {
      setScale(scale - 0.2);
    }
  };

  const renderContent = () => {
    if (!fileUrl) return null;

    if (fileType.includes('pdf')) {
      return (
        <div style={{ textAlign: 'center' }}>
          <div style={{ marginBottom: '10px' }}>
            <button onClick={() => setPageNumber(Math.max(1, pageNumber - 1))} disabled={pageNumber <= 1}>
              上一页
            </button>
            <span style={{ margin: '0 10px' }}>
              第 {pageNumber} 页 / 共 {numPages} 页
            </span>
            <button onClick={() => setPageNumber(Math.min(numPages, pageNumber + 1))} disabled={pageNumber >= numPages}>
              下一页
            </button>
            <button onClick={handleZoomIn} style={{ marginLeft: '10px' }}>放大</button>
            <button onClick={handleZoomOut}>缩小</button>
          </div>
          <Document
            file={fileUrl}
            onLoadSuccess={handleLoadSuccess}
            onLoadError={handleLoadError}
            loading={<Spin size="large" />}
          >
            <Page
              pageNumber={pageNumber}
              scale={scale}
              renderTextLayer={true}
              renderAnnotationLayer={true}
            />
          </Document>
        </div>
      );
    } else if (fileType.includes('image')) {
      return (
        <div style={{ textAlign: 'center' }}>
          <div style={{ marginBottom: '10px' }}>
            <button onClick={handleZoomIn}>放大</button>
            <button onClick={handleZoomOut} style={{ marginLeft: '10px' }}>缩小</button>
          </div>
          <img
            src={fileUrl}
            alt={fileName}
            style={{
              maxWidth: '100%',
              transform: `scale(${scale})`,
              transformOrigin: 'center top',
              transition: 'transform 0.3s'
            }}
          />
        </div>
      );
    } else {
      return (
        <div style={{ textAlign: 'center', padding: '20px' }}>
          <p>当前文件类型不支持预览，请下载后查看</p>
          <a href={fileUrl} target="_blank" rel="noopener noreferrer">
            下载文件
          </a>
        </div>
      );
    }
  };

  return (
    <Modal
      title={fileName || '文件预览'}
      visible={visible}
      onCancel={onClose}
      footer={null}
      width="80%"
      style={{ top: 20 }}
      bodyStyle={{ maxHeight: '80vh', overflow: 'auto' }}
    >
      {loading && <Spin size="large" style={{ display: 'block', margin: '20px auto' }} />}
      {renderContent()}
    </Modal>
  );
};

export default FileViewer;