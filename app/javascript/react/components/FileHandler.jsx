import React, { useState } from "react";

import PendingMessage from "./PendingMessage";

const DEFAULT_UPLOAD_MESSAGE =
  "Glissez et déposez le fichier à analyser ou sélectionnez le.";
const DEFAULT_PENDING_MESSAGE =
  "Calcul des statistiques en cours, merci de patienter";

export default function FileHandler({
  handleFile,
  fileSize,
  multiple = true,
  pendingMessage = DEFAULT_PENDING_MESSAGE,
  uploadMessage = DEFAULT_UPLOAD_MESSAGE,
}) {
  const [isPending, setIsPending] = useState(false);

  const handleFiles = async (filesToHandle) => {
    await Promise.all([...filesToHandle].map(async (file) => handleFile(file)));
    setIsPending(false);
  };

  const handleUploads = (event) => {
    const filesToHandle = event.target.files;
    setIsPending(true);
    handleFiles(filesToHandle);
  };

  return (
    <>
      {/* <p className={styles.description}> */}
      <p className="text-center">{uploadMessage}</p>
      <div style={{ paddingLeft: "33%" }}>
        <input
          type="file"
          className="text-white"
          onChange={handleUploads}
          multiple={multiple}
        />
      </div>

      {isPending && (
        <PendingMessage message={pendingMessage} fileSize={fileSize} />
      )}
    </>
  );
}
