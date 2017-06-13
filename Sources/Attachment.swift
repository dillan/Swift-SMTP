/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// Represents a `Mail`'s attachment.
/// Different SMTP servers have different attachment size limits.
public struct Attachment {
    let type: AttachmentType
    let additionalHeaders: [Header]
    let relatedAttachments: [Attachment]

    /// Initialize a data `Attachment`.
    ///
    /// - Parameters:
    ///     - data: Raw data to be sent as attachment.
    ///     - mime: MIME type of the data.
    ///     - name: File name which will be presented in the mail.
    ///     - inline: Indicates if attachment is inline. To embed the attachment
    ///               in mail content, set to `true`. To send as standalone
    ///               attachment, set to `false`. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the attachment. Defaults
    ///                          to none.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(data: Data,
                mime: String,
                name: String,
                inline: Bool = false,
                additionalHeaders: [Header] = [],
                relatedAttachments: [Attachment] = []) {
        self.init(type: .data(data: data,
                              mime: mime,
                              name: name,
                              inline: inline),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    /// Initialize an `Attachment` from a local file.
    ///
    /// - Parameters:
    ///     - filePath: Path to the local file.
    ///     - mime: MIME type of the file. Defaults to
    ///             `application/octet-stream`.
    ///     - name: Name of the file. Defaults to the name component in its
    ///             file path.
    ///     - inline: Indicates if attachment is inline. To embed the attachment
    ///               in mail content, set to `true`. To send as standalone
    ///               attachment, set to `false`. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the attachment. Defaults
    ///                          to none.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(filePath: String,
                mime: String = "application/octet-stream",
                name: String? = nil,
                inline: Bool = false,
                additionalHeaders: [Header] = [],
                relatedAttachments: [Attachment] = []) {
        let name = name ?? NSString(string: filePath).lastPathComponent
        self.init(type: .file(path: filePath,
                              mime: mime,
                              name: name,
                              inline: inline),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    /// Initialize an HTML `Attachment`.
    ///
    /// - Parameters:
    ///     - htmlContent: Content string of HTML.
    ///     - characterSet: Character encoding of `htmlContent`. Defaults to
    ///                     `utf-8`.
    ///     - alternative: Whether the HTML is an alternative for plain text or
    ///                    not. Defaults to `true`.
    ///     - additionalHeaders: Additional headers for the attachment. Defaults
    ///                          to none.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(htmlContent: String,
                characterSet: String = "utf-8",
                alternative: Bool = true,
                additionalHeaders: [Header] = [],
                relatedAttachments: [Attachment] = []) {
        self.init(type: .html(content: htmlContent,
                              characterSet: characterSet,
                              alternative: alternative),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    private init(type: AttachmentType,
                 additionalHeaders: [Header],
                 relatedAttachments: [Attachment]) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.relatedAttachments = relatedAttachments
    }
}

extension Attachment {
    enum AttachmentType {
        case data(data: Data, mime: String, name: String, inline: Bool)
        case file(path: String, mime: String, name: String, inline: Bool)
        case html(content: String, characterSet: String, alternative: Bool)
    }
}

extension Attachment {
    private var headers: [Header] {
        var headers = [Header]()

        switch type {
        case .data(let data):
            headers.append(("CONTENT-TYPE", data.mime))
            var attachmentDisposition = data.inline ? "inline" : "attachment"
            if let mime = data.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            headers.append(("CONTENT-DISPOSITION", attachmentDisposition))

        case .file(let file):
            headers.append(("CONTENT-TYPE", file.mime))
            var attachmentDisposition = file.inline ? "inline" : "attachment"
            if let mime = file.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            headers.append(("CONTENT-DISPOSITION", attachmentDisposition))

        case .html(let html):
            headers.append(("CONTENT-TYPE", "text/html; charset=\(html.characterSet)"))
            headers.append(("CONTENT-DISPOSITION", "inline"))
        }

        headers.append(("CONTENT-TRANSFER-ENCODING", "BASE64"))

        for header in additionalHeaders {
            headers.append((header.header, header.value))
        }

        return headers
    }

    var headersString: String {
        return headers.map {
            "\($0.0): \($0.1)"
            }.joined(separator: CRLF)
    }
}

extension Attachment {
    var hasRelated: Bool {
        return !relatedAttachments.isEmpty
    }

    var isAlternative: Bool {
        if case .html(let html) = type, html.alternative {
            return true
        }
        return false
    }
}
