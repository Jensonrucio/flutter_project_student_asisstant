-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 13, 2026 at 07:27 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `student_todo_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `auth_login_attempts`
--

CREATE TABLE `auth_login_attempts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `email_hash` char(64) NOT NULL,
  `ip_hash` char(64) NOT NULL,
  `attempted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_login_attempts`
--

INSERT INTO `auth_login_attempts` (`id`, `email_hash`, `ip_hash`, `attempted_at`) VALUES
(6, '01daf2b30b24130a019a896a6c532bc978d2ed8cbbe618e8a09f96769a20de9d', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-09-27 13:16:56'),
(12, '2927c4fc3199415f551df3fb2fe50f9a72aba1a563287e9cf4831ac49a6b6567', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 17:46:39'),
(13, '2927c4fc3199415f551df3fb2fe50f9a72aba1a563287e9cf4831ac49a6b6567', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 17:46:47'),
(14, '2927c4fc3199415f551df3fb2fe50f9a72aba1a563287e9cf4831ac49a6b6567', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 17:47:00'),
(15, '2927c4fc3199415f551df3fb2fe50f9a72aba1a563287e9cf4831ac49a6b6567', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 17:48:52'),
(16, '2927c4fc3199415f551df3fb2fe50f9a72aba1a563287e9cf4831ac49a6b6567', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 17:49:12'),
(10, '92b1f03943cd8c333e4ed18186e473abb76287603d64e457b18e7d6fe3a8613c', '12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0', '2026-10-08 17:31:45'),
(11, '92b1f03943cd8c333e4ed18186e473abb76287603d64e457b18e7d6fe3a8613c', '12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0', '2026-10-08 17:32:13'),
(3, '9a20c4b0e7ba86ef2910f024862e8475b3ff330a310e126c87588cbbda283947', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-09-27 11:19:29'),
(4, '9a20c4b0e7ba86ef2910f024862e8475b3ff330a310e126c87588cbbda283947', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-09-27 11:19:30'),
(1, 'c282a6accdd2702d173f1b40f4eb99300cc3543fc78e2ffe8d2acf25416ee1ca', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-09-27 11:09:12');

-- --------------------------------------------------------

--
-- Table structure for table `auth_password_reset_requests`
--

CREATE TABLE `auth_password_reset_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `email_hash` char(64) NOT NULL,
  `ip_hash` char(64) NOT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_password_reset_requests`
--

INSERT INTO `auth_password_reset_requests` (`id`, `email_hash`, `ip_hash`, `requested_at`) VALUES
(1, '6d205ef23e2b6aff02eb35f165232c70af2adb793ac2f6a3dac6fbfe7d334377', '12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0', '2026-10-08 17:56:15'),
(2, 'a022162b700b6c6e77982ecc70ead0a717564d039cbc789bdf2e0142892e0fc6', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 18:08:18'),
(3, 'a022162b700b6c6e77982ecc70ead0a717564d039cbc789bdf2e0142892e0fc6', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 18:08:18'),
(4, 'a022162b700b6c6e77982ecc70ead0a717564d039cbc789bdf2e0142892e0fc6', 'eff8e7ca506627fe15dda5e0e512fcaad70b6d520f37cc76597fdb4f2d83a1a3', '2026-10-08 18:08:49');

-- --------------------------------------------------------

--
-- Table structure for table `auth_password_reset_tokens`
--

CREATE TABLE `auth_password_reset_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_password_reset_tokens`
--

INSERT INTO `auth_password_reset_tokens` (`id`, `user_id`, `token_hash`, `expires_at`, `used_at`, `created_at`) VALUES
(1, 5, '997d2bf3138139a85427a024df38fd44fc0d46f8f2f43fc55873eed87398defd', '2026-10-08 19:08:18', '2026-10-08 18:08:18', '2026-10-08 18:08:18'),
(2, 5, '248de89a4425498ead56b14b1f45dd36bb6ed48ad6515b5d529c6f3ef0b6a973', '2026-10-08 19:08:18', '2026-10-08 18:08:18', '2026-10-08 18:08:18'),
(3, 5, 'fea65d1e1af7e7dc52c842f4d17253cfe187f07035cc901778c3c00bf39c47ca', '2026-10-08 19:08:49', '2026-10-08 18:08:49', '2026-10-08 18:08:49');

-- --------------------------------------------------------

--
-- Table structure for table `auth_tokens`
--

CREATE TABLE `auth_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_tokens`
--

INSERT INTO `auth_tokens` (`id`, `user_id`, `token_hash`, `expires_at`, `revoked_at`, `created_at`) VALUES
(2, 1, '50e2263c1a6f97f2bf0832697c5ba3ae8e01bcbbcd9034d320f1a17f1ef02c76', '2026-09-28 11:13:43', '2026-09-27 11:13:47', '2026-09-27 11:13:43'),
(3, 1, '37ee66e7025bb57750f48cbbcd4d05cb76c15402c2baa7f2e4aa4b4c4a851281', '2026-09-28 11:20:26', NULL, '2026-09-27 11:20:26'),
(4, 1, 'b344dacff388df66880ad2fa9693987ab2192e9aa00e1b3a1789a4b4f203ef40', '2026-09-28 11:40:13', NULL, '2026-09-27 11:40:13'),
(5, 1, 'ec2c07202c1a847b4777ec48347e70569c0ce4ea7a5d90d26949ac52d9ad8def', '2026-09-28 11:49:44', NULL, '2026-09-27 11:49:44'),
(6, 1, '60927d6221a07a80c89fea666d91b173a0ffa49fca9a28c6b5ea783ee7968ef3', '2026-09-28 12:03:25', '2026-09-27 12:03:30', '2026-09-27 12:03:25'),
(7, 1, '57380d8476696991bad621a54b5e04ec6cbb63cac2ff49207365fcd91d78d03b', '2026-09-28 12:03:45', '2026-09-27 12:04:33', '2026-09-27 12:03:45'),
(8, 1, '05a55af9c94745c37b40cd584b76cf28edea83da45b04652083d40480f585224', '2026-09-28 12:04:44', '2026-09-27 12:36:31', '2026-09-27 12:04:44'),
(9, 1, 'cf0ffb1c89c6df9b8cd3d7904e72899be34f0d3cc9da83082833fb62c6a57f8a', '2026-09-28 12:57:27', NULL, '2026-09-27 12:57:27'),
(10, 1, '612654436ffdfb31003443e3386f32e8ce6f6c7959ee347de3df4897c7a7b07b', '2026-09-28 13:19:51', NULL, '2026-09-27 13:19:51'),
(11, 1, '14736f5d6da1f4d5a8fde52c4fd3580fe6d16ec698fc69323a8d6ec2fd3d102e', '2026-09-28 13:32:54', '2026-09-27 13:33:09', '2026-09-27 13:32:54'),
(12, 1, '0413198217f0802d7d41260593ef68947f96a27c629c9a61a4babe116c462cbf', '2026-09-28 13:33:18', '2026-09-27 13:33:25', '2026-09-27 13:33:18'),
(13, 2, '2506888cd64e2efd18aad4d4f87769c1e3cc14bbe5d38e92338921b9dd9a7270', '2026-09-28 13:34:00', '2026-09-27 13:34:05', '2026-09-27 13:34:00'),
(14, 2, 'a820ce8c2a95f82b609cdb4e04f7366ff63c103e35bdc25db03ca0e72c2a58a5', '2026-09-28 13:34:16', '2026-09-27 13:34:20', '2026-09-27 13:34:16'),
(15, 1, '53b0814c8c180cb3d42cb000b11645bfe557f32fc0d258f65be1c11018fc35a7', '2026-09-28 13:47:13', NULL, '2026-09-27 13:47:13'),
(16, 1, '9eb438ce27037660ab376be8824d43c2f3e016fbeded17f7982f454ebd61833f', '2026-09-28 14:09:30', NULL, '2026-09-27 14:09:30'),
(17, 1, 'd22ba93707f8a28e1d7af631bd8f4a4def8e9561a886f965df985ca55382c527', '2026-09-28 14:11:45', NULL, '2026-09-27 14:11:45'),
(18, 1, '5f6a39f56caa170db2f71553ab4a03a9e1d31a4ccc319e4c478016454bafe928', '2026-09-28 14:15:36', '2026-09-27 14:17:13', '2026-09-27 14:15:36'),
(19, 1, '131de491d9ac21bcfc5b38554d4d7e5950278e0d8ea0ad48fc14458e6133b05a', '2026-09-29 00:34:49', '2026-09-28 00:53:03', '2026-09-28 00:34:49'),
(20, 1, '475ae2db7e594b9dcb89443deef33beb4ff00759dfc5cf7dafdc70d7fa37a18e', '2026-09-29 10:57:04', NULL, '2026-09-28 10:57:04'),
(21, 1, 'ca33280f30afd3092736409c3942cd300f50f845748c422e986cf94d6aade8bd', '2026-10-02 15:36:17', NULL, '2026-10-01 15:36:17'),
(22, 1, '5c50c45a0a873a731a9df5a7cf905403359112acd6b90f355215fb8ecdc2089c', '2026-10-02 15:37:44', NULL, '2026-10-01 15:37:44'),
(23, 1, '9aa26c1c6944e478b6d251f013e7c2526256a2160d5cfd6ad3bda094bc2edb8e', '2026-10-02 16:31:44', NULL, '2026-10-01 16:31:44'),
(24, 1, 'd627a5f02e2caf6e5e86b17fb8cf6d603728b98e4f71a35749aa40c0a0fa507f', '2026-10-02 16:32:42', NULL, '2026-10-01 16:32:42'),
(25, 1, 'ed23bebdc9ba712a7c243475f17e4ca0533b01cd227b2618291b3cc6292be857', '2026-10-02 16:48:21', NULL, '2026-10-01 16:48:21'),
(26, 1, '1fc15dd3c9f70c15bfd449b7b0e9ad5c07a3f243f65bafb5152abe3682d2ef14', '2026-10-02 16:49:12', NULL, '2026-10-01 16:49:12'),
(27, 1, '18d59b906e01333af6b080467f3f90d31c1d54ae4f886b27d65f5321c25a55e0', '2026-10-02 16:55:44', NULL, '2026-10-01 16:55:44'),
(28, 1, '6b9773a616d68c4bd096b1113529c7b126ac60c284733d8ed06cac6c67ae0c77', '2026-10-02 16:56:34', NULL, '2026-10-01 16:56:34'),
(29, 4, '43a35d96cc9ca4abd3f391b32686998cf5e7458aa9c9ae4ddffce366ca6dba1a', '2026-10-09 17:36:40', NULL, '2026-10-08 17:36:40'),
(30, 5, '86778a786406f5410d96f2712657460ef5d7e6b8d23f4b114ee8ea7cbb88c04a', '2026-10-09 18:02:28', NULL, '2026-10-08 18:02:28'),
(31, 5, '58b6dfd7946f561eaffbffe7ff823de6b66e69edc905c39a0e5d81448791d363', '2026-10-09 18:10:16', NULL, '2026-10-08 18:10:16'),
(32, 5, '91aac53be84c8a4b8792fa02712832a35b43e4ae1cd42f779423877a99fe5866', '2026-10-09 18:13:04', NULL, '2026-10-08 18:13:04'),
(33, 5, '085004f1899a5ff365c4f1406a4f889a1dbac8750cb63fc87c8db536bbde9340', '2026-10-09 18:25:38', NULL, '2026-10-08 18:25:38'),
(34, 5, '69c76ff70a8a9b73394852eb1e3b83ada00b58c26fdbb1c202351b5413742a59', '2026-10-09 18:35:42', NULL, '2026-10-08 18:35:42'),
(35, 5, '3b181b8e94c6942dae9d9761143de3e7984e95889a7439840d2d4a4284217590', '2026-10-09 18:39:35', NULL, '2026-10-08 18:39:35'),
(36, 5, '0546d616ac907feb04aeb6dd9155f035c7b068a10543d3a398e988aee5fa3876', '2026-10-09 18:47:22', NULL, '2026-10-08 18:47:22'),
(37, 5, 'fee4ff280ca7e846412eaac7d687cf8dce7bb5557ed2e387a5fde0d967dd8449', '2026-10-09 19:02:53', NULL, '2026-10-08 19:02:53'),
(38, 5, 'f45d8e4b6e83ad3d7e43c1727cc51a3019e43a83108effac19b59aa3c9fafb46', '2026-10-09 19:08:42', NULL, '2026-10-08 19:08:42'),
(39, 5, '56ef91dcbdf97fad83840b44b01533c5c316d550c3ea509c76cd8b12f2124a8d', '2026-10-09 19:18:07', NULL, '2026-10-08 19:18:07'),
(40, 5, 'f5c1124c0811a5e0de9385dfba49e852ca80a33875870d8c46b1ed3e2ac3d12f', '2026-10-09 19:20:39', NULL, '2026-10-08 19:20:39'),
(41, 5, 'f761e7ae44070c491569f8fd78079432136ce31d2dd201ec74ea0e9022ead1f1', '2026-10-11 07:49:15', NULL, '2026-10-10 07:49:15'),
(42, 5, 'baeaac9cd564e1a7befab2c92985fb11dbcddb8e47e79bf9bb81048184c7893b', '2026-10-11 08:16:38', NULL, '2026-10-10 08:16:38'),
(43, 5, '3179ee961737062eb81eb94475d0b197e897cf6c9ca9a18edcf350037a8d70d7', '2026-10-11 08:25:15', NULL, '2026-10-10 08:25:15'),
(44, 5, '95cac1a2da2703994853991bf447dd533b68e78b5d52b8f3d4f7737f950562e0', '2026-10-11 08:29:53', NULL, '2026-10-10 08:29:53');

-- --------------------------------------------------------

--
-- Table structure for table `auth_users`
--

CREATE TABLE `auth_users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(254) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_users`
--

INSERT INTO `auth_users` (`id`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'admin123', 'admin@gmail.com', '$2y$10$sk8mCfRkIa/6jXIJdDSKnuYvMsnk1ZrbrEMERKXj9qZPSWn2Zfn8.', '2026-09-27 11:11:33'),
(2, 'demo', 'demo@gmail.com', '$2y$10$zEb3C/R4QKdYHWjIooNaaejX4kUy9SW0k56q0CbPOju7ZC1VfHvg2', '2026-09-27 13:34:00'),
(4, 'admin1', 'admin123@gmail.com', '$2y$10$R024wUJMNBy6c0j8kKRYD.mFUbipWy.Iuev2ki0D3ENdIVOOvSky6', '2026-10-08 17:36:40'),
(5, 'jensonrucio', 'jensonrucio00@gmail.com', '$2y$10$YrvrkOsUau/ijkUBeoN2TOMkVHtSMoGp2p5uU8qSeZJJFbAyWqlWK', '2026-10-08 18:02:28');

-- --------------------------------------------------------

--
-- Table structure for table `quiz_logs`
--

CREATE TABLE `quiz_logs` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `topic` varchar(500) NOT NULL,
  `score` int(10) UNSIGNED NOT NULL,
  `total_questions` int(10) UNSIGNED NOT NULL,
  `percentage` decimal(5,2) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(64) NOT NULL DEFAULT 'Homework',
  `priority` varchar(32) NOT NULL DEFAULT 'Medium',
  `due_date` datetime NOT NULL,
  `is_completed` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `auth_login_attempts`
--
ALTER TABLE `auth_login_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_auth_attempts_window` (`email_hash`,`ip_hash`,`attempted_at`);

--
-- Indexes for table `auth_password_reset_requests`
--
ALTER TABLE `auth_password_reset_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_password_reset_requests_window` (`email_hash`,`ip_hash`,`requested_at`);

--
-- Indexes for table `auth_password_reset_tokens`
--
ALTER TABLE `auth_password_reset_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token_hash` (`token_hash`),
  ADD KEY `idx_password_reset_tokens_user` (`user_id`,`expires_at`);

--
-- Indexes for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token_hash` (`token_hash`),
  ADD KEY `idx_auth_tokens_user_expiry` (`user_id`,`expires_at`);

--
-- Indexes for table `auth_users`
--
ALTER TABLE `auth_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `quiz_logs`
--
ALTER TABLE `quiz_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_quiz_logs_user_completed` (`user_id`,`completed_at`);

--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tasks_user_due` (`user_id`,`due_date`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `auth_login_attempts`
--
ALTER TABLE `auth_login_attempts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `auth_password_reset_requests`
--
ALTER TABLE `auth_password_reset_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `auth_password_reset_tokens`
--
ALTER TABLE `auth_password_reset_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `auth_users`
--
ALTER TABLE `auth_users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `quiz_logs`
--
ALTER TABLE `quiz_logs`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `auth_password_reset_tokens`
--
ALTER TABLE `auth_password_reset_tokens`
  ADD CONSTRAINT `fk_password_reset_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `auth_users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD CONSTRAINT `fk_auth_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `auth_users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
